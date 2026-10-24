import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/group_khatmah/data/eligibility_requesting_remote.dart';
import 'package:talia_quran/features/group_khatmah/data/group_khatmah_remote.dart';
import 'package:talia_quran/features/group_khatmah/data/supabase_group_khatmah_remote.dart';
import 'package:talia_quran/features/group_khatmah/domain/entities/group_khatmah.dart';

void main() {
  late _Remote inner;
  late List<String> asked;
  late Future<bool> Function(String) answer;
  var now = DateTime(2027);

  EligibilityRequestingRemote build() => EligibilityRequestingRemote(
    inner,
    requestEligibility: (owner) {
      asked.add(owner);
      return answer(owner);
    },
    clock: () => now,
  );

  setUp(() {
    inner = _Remote();
    asked = [];
    answer = (_) async => true;
    now = DateTime(2027);
  });

  test('a first not_eligible create asks once and repeats the same request', () async {
    inner.responses = [_notEligible, _created];
    final remote = build();
    final args = {'p_title': 'Family', 'p_request_id': 'r1'};
    final result = await remote.rpc('create_group_khatmah', args, ownerId: 'a');
    expect(result['code'], 'created');
    expect(asked, ['a']);
    expect(inner.calls, [
      ('create_group_khatmah', args),
      ('create_group_khatmah', args),
    ]);
  });

  test('a refusal is returned as is and not asked again for ten minutes', () async {
    answer = (_) async => false;
    inner.responses = [_notEligible, _notEligible, _notEligible];
    final remote = build();
    expect(
      (await remote.rpc('join_group_khatmah', const {}, ownerId: 'a'))['code'],
      'not_eligible',
    );
    now = now.add(const Duration(minutes: 9));
    expect(
      (await remote.rpc('join_group_khatmah', const {}, ownerId: 'a'))['code'],
      'not_eligible',
    );
    expect(asked, ['a']);
    now = now.add(const Duration(minutes: 1));
    await remote.rpc('join_group_khatmah', const {}, ownerId: 'a');
    expect(asked, ['a', 'a']);
    expect(inner.calls, hasLength(3));
  });

  test('a failed request (e.g. not deployed) keeps the refusal and may ask '
      'again later', () async {
    answer = (_) async => throw StateError('function missing');
    inner.responses = [_notEligible, _notEligible];
    final remote = build();
    await remote.rpc('create_group_khatmah', const {}, ownerId: 'a');
    await remote.rpc('create_group_khatmah', const {}, ownerId: 'a');
    expect(asked, ['a', 'a']);
    expect(inner.calls, hasLength(2));
  });

  test('an owner change propagates and does not block a later ask', () async {
    var changed = true;
    answer = (_) async {
      if (changed) throw const GroupRemoteOwnerChanged();
      return true;
    };
    inner.responses = [_notEligible, _notEligible, _created];
    final remote = build();
    await expectLater(
      remote.rpc('create_group_khatmah', const {}, ownerId: 'a'),
      throwsA(isA<GroupRemoteOwnerChanged>()),
    );
    changed = false;
    final result = await remote.rpc(
      'create_group_khatmah',
      const {},
      ownerId: 'a',
    );
    expect(result['code'], 'created');
  });

  test('other calls and other codes pass straight through', () async {
    inner.responses = [_notEligible, _conflict];
    final remote = build();
    expect(
      (await remote.rpc('claim_group_part', const {}, ownerId: 'a'))['code'],
      'not_eligible',
    );
    expect(
      (await remote.rpc('join_group_khatmah', const {}, ownerId: 'a'))['code'],
      'conflict',
    );
    expect(asked, isEmpty);
  });
}

const _notEligible = {'applied': false, 'code': 'not_eligible'};
const _created = {'applied': true, 'code': 'created'};
const _conflict = {'applied': false, 'code': 'conflict'};

class _Remote implements GroupKhatmahRemote {
  List<Map<String, dynamic>> responses = [];
  final calls = <(String, Map<String, dynamic>)>[];

  @override
  Future<Map<String, dynamic>> rpc(
    String function,
    Map<String, dynamic> args, {
    required String ownerId,
  }) async {
    calls.add((function, args));
    return Map<String, dynamic>.from(responses.removeAt(0));
  }

  @override
  Future<GroupKhatmahPage> fetchMine({
    required String ownerId,
    String? cursor,
  }) => throw UnimplementedError();

  @override
  Future<GroupKhatmah?> fetchGroup({
    required String ownerId,
    required String groupId,
  }) => throw UnimplementedError();
}
