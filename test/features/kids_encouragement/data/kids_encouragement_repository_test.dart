import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/kids_encouragement/data/kids_encouragement_repository_impl.dart';
import 'package:talia_quran/features/kids_encouragement/domain/entities/kids_encouragement.dart';

void main() {
  group('KidsEncouragementRepositoryImpl', () {
    late SharedPreferences prefs;
    late _Owner owner;
    late _Transport transport;
    late AccountDataBarrier barrier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      owner = _Owner('parent-a');
      barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      transport = _Transport();
    });

    KidsEncouragementRepositoryImpl repository({bool enabled = true}) {
      return KidsEncouragementRepositoryImpl(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        isEnabled: () => enabled,
        rpc: transport.rpc,
        selectForChild: transport.select,
        selectSeen: (ids) async => transport.seenReply
            .where((row) => ids.contains(row['id']))
            .toList(),
      );
    }

    test('feature off performs no transport or preference I/O', () async {
      final repo = repository(enabled: false);
      final sent = await repo.send(
        childUserId: 'child-a',
        message: KidsEncouragementMessage.proud,
        sticker: KidsEncouragementSticker.starReward,
        clientRequestId: '00000000-0000-4000-8000-000000000001',
      );
      final loaded = await repo.refresh(childUserId: 'child-a');

      expect(sent, isA<KidsEncouragementSendDisabled>());
      expect(loaded, isEmpty);
      expect(transport.calls, isEmpty);
      expect(prefs.getKeys(), isEmpty);
    });

    test(
      'encodes only fixed keys and returns the authoritative RPC row',
      () async {
        transport.rpcReply = [
          _row(
            id: 4,
            child: 'child-a',
            message: 'well_done',
            sticker: 'talia_encourage',
            request: '00000000-0000-4000-8000-000000000002',
          ),
        ];
        final result = await repository().send(
          childUserId: 'child-a',
          message: KidsEncouragementMessage.wellDone,
          sticker: KidsEncouragementSticker.taliaEncourage,
          clientRequestId: '00000000-0000-4000-8000-000000000002',
        );

        expect(result, isA<KidsEncouragementSendSuccess>());
        final params = transport.calls.single.params;
        expect(transport.calls.single.name, 'send_kids_encouragement');
        expect(params, {
          'p_child_user_id': 'child-a',
          'p_message_key': 'well_done',
          'p_sticker_key': 'talia_encourage',
          'p_client_request_id': '00000000-0000-4000-8000-000000000002',
        });
        expect((result as KidsEncouragementSendSuccess).encouragement.id, 4);
      },
    );

    test('invalid UUID is rejected before the RPC', () async {
      await expectLater(
        repository().send(
          childUserId: 'child-a',
          message: KidsEncouragementMessage.proud,
          sticker: KidsEncouragementSticker.starReward,
          clientRequestId: 'not-a-uuid',
        ),
        throwsFormatException,
      );
      expect(transport.calls, isEmpty);
    });

    test(
      'rejects a malformed or mismatched authoritative RPC response',
      () async {
        final repo = repository();
        transport.rpcReply = [_row(id: 4, child: 'different-child')];
        await expectLater(
          repo.send(
            childUserId: 'child-a',
            message: KidsEncouragementMessage.proud,
            sticker: KidsEncouragementSticker.starReward,
            clientRequestId: '00000000-0000-4000-8000-000000000002',
          ),
          throwsFormatException,
        );
        transport.rpcReply = [
          {'id': '4'},
        ];
        await expectLater(
          repo.send(
            childUserId: 'child-a',
            message: KidsEncouragementMessage.proud,
            sticker: KidsEncouragementSticker.starReward,
            clientRequestId: '00000000-0000-4000-8000-000000000002',
          ),
          throwsFormatException,
        );
        expect(repo.cached(childUserId: 'child-a'), isEmpty);
      },
    );

    test(
      'refresh replaces cached rows and drops inaccessible rows on empty RLS result',
      () async {
        transport.selectReply = [_row(id: 1, child: 'child-a')];
        final repo = repository();
        expect(await repo.refresh(childUserId: 'child-a'), hasLength(1));
        transport.selectReply = [];
        expect(await repo.refresh(childUserId: 'child-a'), isEmpty);
        expect(repo.cached(childUserId: 'child-a'), isEmpty);
      },
    );

    test(
      'owner switch rejects a post-await response and does not populate the next account cache',
      () async {
        final repo = repository();
        transport.onSelect = () => owner.currentOwnerId = 'parent-b';
        transport.selectReply = [_row(id: 1, child: 'child-a')];
        await expectLater(
          repo.refresh(childUserId: 'child-a'),
          throwsA(isA<AccountDataUnavailableException>()),
        );
        expect(repo.cached(childUserId: 'child-a'), isEmpty);
      },
    );

    test(
      'seen batches are capped and failed acknowledgements are retained per owner for retry',
      () async {
        final repo = repository();
        await expectLater(
          repo.markSeen(List<int>.generate(101, (index) => index + 1)),
          throwsRangeError,
        );
        transport.rpcError = StateError('offline');
        await expectLater(repo.markSeen([7, 7, 8]), throwsStateError);
        expect(await repo.pendingSeenIds(), [7, 8]);

        transport.rpcError = null;
        transport.rpcReply = 2;
        expect(await repo.retryPendingSeen(), 2);
        expect(await repo.pendingSeenIds(), isEmpty);
        expect(transport.calls.last.params, {
          'p_ids': [7, 8],
        });
      },
    );

    test('pending seen receipts are account scoped', () async {
      final repo = repository();
      transport.rpcError = StateError('offline');
      await expectLater(repo.markSeen([7]), throwsStateError);
      owner.currentOwnerId = 'parent-b';
      barrier.prepareOwner('parent-b');
      await barrier.markOwnerReady('parent-b');
      final other = repository();
      expect(await other.pendingSeenIds(), isEmpty);
    });

    test('pending seen receipts replay after a repository restart', () async {
      final first = repository();
      transport.rpcError = StateError('offline');
      await expectLater(first.markSeen([9]), throwsStateError);
      transport.rpcError = null;
      transport.rpcReply = 1;
      final restarted = repository();
      expect(await restarted.retryPendingSeen(), 1);
      expect(await restarted.pendingSeenIds(), isEmpty);
    });

    test(
      'zero updated rows do not discard a hidden or revoked-link receipt',
      () async {
        final repo = repository();
        transport.rpcReply = 0;
        expect(await repo.markSeen([7]), 0);
        expect(await repo.pendingSeenIds(), [7]);
      },
    );

    test(
      'partial and repeated acknowledgements remove only explicitly seen ids',
      () async {
        final repo = repository();
        transport.rpcReply = 1;
        transport.seenReply = [
          {
            'id': 7,
            'child_user_id': 'parent-a',
            'seen_at': '2026-10-21T12:00:00Z',
          },
        ];
        await repo.markSeen([7, 8]);
        expect(await repo.pendingSeenIds(), [8]);
        transport.rpcReply = 0;
        transport.seenReply = [
          {
            'id': 8,
            'child_user_id': 'parent-a',
            'seen_at': '2026-10-21T12:01:00Z',
          },
        ];
        await repo.retryPendingSeen();
        expect(await repo.pendingSeenIds(), isEmpty);
      },
    );

    test('pending receipts are capped to the newest 200 ids', () async {
      final repo = repository();
      transport.rpcReply = 0;
      for (var batch = 0; batch < 3; batch++) {
        await repo.markSeen(
          List.generate(100, (index) => batch * 100 + index + 1),
        );
      }
      expect(
        await repo.pendingSeenIds(),
        List.generate(200, (index) => index + 101),
      );
    });

    test('a full hidden batch cannot starve a later active receipt', () async {
      final repo = repository();
      transport.rpcReply = 0;
      await repo.markSeen(List.generate(100, (index) => index + 1));
      await repo.markSeen([101]);
      transport.calls.clear();
      transport.seenReply = [
        {
          'id': 101,
          'child_user_id': 'parent-a',
          'seen_at': '2026-10-21T12:00:00Z',
        },
      ];
      await repo.retryPendingSeen();
      expect(transport.calls, hasLength(2));
      expect(
        await repo.pendingSeenIds(),
        List.generate(100, (index) => index + 1),
      );
    });
  });
}

Map<String, dynamic> _row({
  required int id,
  required String child,
  String parent = 'parent-a',
  String message = 'proud',
  String sticker = 'star_reward',
  String request = '00000000-0000-4000-8000-000000000001',
}) => {
  'id': id,
  'parent_user_id': parent,
  'child_user_id': child,
  'message_key': message,
  'sticker_key': sticker,
  'created_at': '2026-10-21T12:00:00.000Z',
  'seen_at': null,
  'client_request_id': request,
};

final class _Owner implements RecordOwnerProvider {
  _Owner(this.currentOwnerId);
  @override
  String currentOwnerId;
  @override
  bool get isSignedIn => true;
}

final class _Call {
  const _Call(this.name, this.params);
  final String name;
  final Map<String, dynamic> params;
}

final class _Transport {
  final calls = <_Call>[];
  Object? rpcReply;
  Object? rpcError;
  List<Map<String, dynamic>> selectReply = [];
  List<Map<String, dynamic>> seenReply = [];
  void Function()? onSelect;

  Future<Object?> rpc(String name, Map<String, dynamic> params) async {
    calls.add(_Call(name, params));
    if (rpcError != null) throw rpcError!;
    return rpcReply;
  }

  Future<List<Map<String, dynamic>>> select(String childUserId) async {
    onSelect?.call();
    return selectReply;
  }
}
