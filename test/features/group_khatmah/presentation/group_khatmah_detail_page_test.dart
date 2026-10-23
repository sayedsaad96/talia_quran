import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/group_khatmah/domain/entities/group_khatmah.dart';
import 'package:talia_quran/features/group_khatmah/domain/repositories/group_khatmah_repository.dart';
import 'package:talia_quran/features/group_khatmah/presentation/cubits/group_khatmah_cubit.dart';
import 'package:talia_quran/features/group_khatmah/presentation/pages/group_khatmah_detail_page.dart';
import 'package:talia_quran/features/group_khatmah/presentation/pages/group_khatmah_join_sheet.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatm_dua_datasource.dart';

const ownerId = '11111111-1111-4111-8111-111111111111';
const otherId = '22222222-2222-4222-8222-222222222222';
const groupId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

class MutableOwner implements RecordOwnerProvider {
  MutableOwner(this.currentOwnerId);
  @override
  String currentOwnerId;
  @override
  bool get isSignedIn => currentOwnerId.isNotEmpty;
}

GroupKhatmah sampleGroup({
  GroupKhatmahStatus status = GroupKhatmahStatus.active,
  bool pending = false,
  bool failed = false,
  bool allCompleted = false,
}) => GroupKhatmah(
  id: groupId,
  code: 'ABC234',
  title: 'Shared reading',
  ownerId: ownerId,
  maxMembers: 30,
  status: status,
  version: 2,
  createdAt: DateTime.utc(2026, 10, 23),
  completedAt: status == GroupKhatmahStatus.completed
      ? DateTime.utc(2026, 10, 24)
      : null,
  membershipEpoch: 'epoch',
  members: [
    GroupMember(
      groupId: groupId,
      userId: ownerId,
      displayName: 'Owner Name',
      joinedAt: DateTime.utc(2026, 10, 23),
      leftAt: null,
      membershipEpoch: 'epoch',
    ),
    GroupMember(
      groupId: groupId,
      userId: otherId,
      displayName: 'Other Name',
      joinedAt: DateTime.utc(2026, 10, 23),
      leftAt: null,
      membershipEpoch: 'other-epoch',
    ),
  ],
  parts: [
    for (var juz = 1; juz <= 30; juz++)
      GroupPart(
        groupId: groupId,
        juz: juz,
        status: allCompleted
            ? GroupPartStatus.completed
            : juz == 1 || juz == 2
            ? GroupPartStatus.claimed
            : GroupPartStatus.open,
        claimedBy: allCompleted || juz == 1
            ? ownerId
            : juz == 2
            ? otherId
            : null,
        claimEpoch: allCompleted || juz == 1
            ? 'epoch'
            : juz == 2
            ? 'other-epoch'
            : null,
        version: 1,
        updatedAt: DateTime.utc(2026, 10, 23),
        isCompletionPending: juz == 1 && pending,
        isCompletionFailed: juz == 1 && failed,
      ),
  ],
);

class FakeGroupRepository implements GroupKhatmahRepository {
  FakeGroupRepository(this.group);
  GroupKhatmah group;
  Failure? nextFailure;
  Failure? refreshFailure;
  int createCalls = 0;
  int joinCalls = 0;
  int retryCalls = 0;
  int discardCalls = 0;
  List<GroupFailedOperation> failed = [];
  @override
  List<GroupFailedOperation> failedOperations() => failed;
  @override
  Future<Either<Failure, void>> retryFailedOperation(String operationId) async {
    retryCalls++;
    failed = [];
    publish(group);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> discardFailedOperation(
    String operationId,
  ) async {
    discardCalls++;
    failed = [];
    publish(group);
    return const Right(null);
  }

  Future<Either<Failure, GroupPart>> Function(int juz)? onClaim;
  final controller = StreamController<List<GroupKhatmah>>.broadcast(sync: true);

  @override
  Stream<List<GroupKhatmah>> watchMine() => Stream.multi((sink) {
    sink.add([group]);
    final subscription = controller.stream.listen(sink.add, onDone: sink.close);
    sink.onCancel = subscription.cancel;
  });

  void publish(GroupKhatmah value) {
    group = value;
    controller.add([value]);
  }

  @override
  Future<Either<Failure, void>> refreshMine() async =>
      refreshFailure == null ? const Right(null) : Left(refreshFailure!);
  @override
  Future<Either<Failure, void>> reconcilePendingWake() async =>
      const Right(null);
  @override
  Future<Either<Failure, GroupKhatmah>> create(
    String title,
    String name,
  ) async {
    createCalls++;
    publish(group);
    return Right(group);
  }

  @override
  Future<Either<Failure, GroupKhatmah>> join(String code, String name) async {
    joinCalls++;
    publish(group);
    return Right(group);
  }

  @override
  Future<Either<Failure, GroupPart>> claim(String id, int juz) async =>
      onClaim != null
      ? onClaim!(juz)
      : nextFailure == null
      ? Right(group.part(juz)!)
      : Left(nextFailure!);
  @override
  Future<Either<Failure, GroupPart>> release(String id, int juz) async =>
      Right(group.part(juz)!);
  @override
  Future<Either<Failure, void>> completeLocally(String id, int juz) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> retryFailedCompletion(
    String id,
    int juz,
  ) async {
    retryCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> discardFailedCompletion(
    String id,
    int juz,
  ) async {
    discardCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> leave(String id) async => const Right(null);
  @override
  Future<Either<Failure, void>> flushPending() async => const Right(null);
  @override
  Future<bool> hasPending() async => false;
  @override
  Future<bool> hasRunnablePending() async => false;
  @override
  Future<void> dispose() => controller.close();
}

class FakeDuaDatasource extends KhatmDuaDatasource {
  FakeDuaDatasource(this.data);
  final KhatmDuaData data;
  @override
  Future<KhatmDuaData> loadDua() async => data;
}

Future<void> pumpDetail(
  WidgetTester tester,
  GroupKhatmahCubit cubit, {
  KhatmDuaDatasource? dua,
  Future<void> Function(String)? share,
  Size size = const Size(390, 844),
  double textScale = 1,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: ThemeData(brightness: brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: GroupKhatmahDetailPage(
        cubit: cubit,
        groupId: groupId,
        duaDatasource: dua,
        onShareCode: share,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders all thirty parts, names, and owner actions', (
    tester,
  ) async {
    final repo = FakeGroupRepository(sampleGroup());
    final cubit = GroupKhatmahCubit(
      repository: repo,
      owner: const FixedRecordOwnerProvider(ownerId),
    )..start();
    addTearDown(() async {
      await cubit.close();
      await repo.dispose();
    });
    await pumpDetail(tester, cubit);
    expect(find.byKey(const Key('group-part-30')), findsOneWidget);
    expect(find.byKey(const Key('group-part-1')), findsOneWidget);
    expect(find.text('Other Name'), findsWidgets);
    expect(find.textContaining('@'), findsNothing);
    expect(find.byKey(const Key('group-part-complete-1')), findsOneWidget);
    expect(find.byKey(const Key('group-part-complete-2')), findsNothing);
  });

  testWidgets('pending completion stays distinct and conflict is shown', (
    tester,
  ) async {
    final repo = FakeGroupRepository(sampleGroup(pending: true));
    final cubit = GroupKhatmahCubit(
      repository: repo,
      owner: const FixedRecordOwnerProvider(ownerId),
    )..start();
    addTearDown(() async {
      await cubit.close();
      await repo.dispose();
    });
    await pumpDetail(tester, cubit);
    expect(find.byKey(const Key('group-part-pending-1')), findsOneWidget);
    repo.nextFailure = const GroupPartConflictFailure();
    await tester.ensureVisible(find.byKey(const Key('group-part-claim-3')));
    await tester.tap(find.byKey(const Key('group-part-claim-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-khatmah-error')), findsOneWidget);
  });

  testWidgets('share callback gets only invitation code', (tester) async {
    final repo = FakeGroupRepository(sampleGroup());
    final cubit = GroupKhatmahCubit(
      repository: repo,
      owner: const FixedRecordOwnerProvider(ownerId),
    )..start();
    addTearDown(() async {
      await cubit.close();
      await repo.dispose();
    });
    String? shared;
    await pumpDetail(tester, cubit, share: (code) async => shared = code);
    await tester.tap(find.byKey(const Key('group-khatmah-share')));
    await tester.pumpAndSettle();
    expect(shared, 'ABC234');
  });

  testWidgets('unapproved dua cannot open and 320dp large text fits', (
    tester,
  ) async {
    final repo = FakeGroupRepository(
      sampleGroup(status: GroupKhatmahStatus.completed, allCompleted: true),
    );
    final cubit = GroupKhatmahCubit(
      repository: repo,
      owner: const FixedRecordOwnerProvider(ownerId),
    )..start();
    addTearDown(() async {
      await cubit.close();
      await repo.dispose();
    });
    final dua = FakeDuaDatasource(
      const KhatmDuaData(
        arabicText: 'fixture only',
        source: 'fixture',
        sourceNote: 'fixture',
        tier: 'fixture',
        dedicationInserts: {},
        reviewStatus: 'pendingReview',
      ),
    );
    await pumpDetail(
      tester,
      cubit,
      dua: dua,
      size: const Size(320, 720),
      textScale: 2,
    );
    expect(find.byKey(const Key('group-khatmah-dua-open')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed completion offers explicit retry and confirmed discard', (
    tester,
  ) async {
    final repo = FakeGroupRepository(sampleGroup(failed: true));
    final cubit = GroupKhatmahCubit(
      repository: repo,
      owner: const FixedRecordOwnerProvider(ownerId),
    )..start();
    addTearDown(() async {
      await cubit.close();
      await repo.dispose();
    });
    await pumpDetail(tester, cubit);
    expect(find.byKey(const Key('group-part-pending-1')), findsNothing);
    expect(find.byKey(const Key('group-part-failed-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('group-part-retry-1')));
    await tester.pumpAndSettle();
    expect(repo.retryCalls, 1);
    await tester.tap(find.byKey(const Key('group-part-discard-1')));
    await tester.pumpAndSettle();
    expect(repo.discardCalls, 0);
    await tester.tap(find.text('Confirm').last);
    await tester.pumpAndSettle();
    expect(repo.discardCalls, 1);
  });

  testWidgets('create form rejects invalid Unicode length and control input', (
    tester,
  ) async {
    final repo = FakeGroupRepository(sampleGroup());
    final cubit = GroupKhatmahCubit(
      repository: repo,
      owner: const FixedRecordOwnerProvider(ownerId),
    );
    addTearDown(() async {
      await cubit.close();
      await repo.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GroupKhatmahJoinSheet(cubit: cubit, isCreate: true),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('group-khatmah-first-input')),
      List.filled(81, 'x').join(),
    );
    await tester.enterText(
      find.byKey(const Key('group-khatmah-name-input')),
      'A\u202E',
    );
    await tester.tap(find.byKey(const Key('group-khatmah-submit')));
    await tester.pumpAndSettle();
    expect(repo.createCalls, 0);
    expect(find.text('Use 1–80 characters for the title.'), findsOneWidget);
    expect(
      find.text('Use 2–24 characters for the display name.'),
      findsOneWidget,
    );
  });

  testWidgets('join form rejects malformed invitation before repository call', (
    tester,
  ) async {
    final repo = FakeGroupRepository(sampleGroup());
    final cubit = GroupKhatmahCubit(
      repository: repo,
      owner: const FixedRecordOwnerProvider(ownerId),
    );
    addTearDown(() async {
      await cubit.close();
      await repo.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GroupKhatmahJoinSheet(cubit: cubit, isCreate: false),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('group-khatmah-first-input')),
      '0O0O0O',
    );
    await tester.enterText(
      find.byKey(const Key('group-khatmah-name-input')),
      'Reader',
    );
    await tester.tap(find.byKey(const Key('group-khatmah-submit')));
    await tester.pumpAndSettle();
    expect(repo.joinCalls, 0);
  });

  testWidgets('late claim result cannot publish under another account', (
    tester,
  ) async {
    final repo = FakeGroupRepository(sampleGroup());
    final owner = MutableOwner(ownerId);
    final pending = Completer<Either<Failure, GroupPart>>();
    repo.onClaim = (_) => pending.future;
    final cubit = GroupKhatmahCubit(repository: repo, owner: owner)..start();
    addTearDown(() async {
      await cubit.close();
      await repo.dispose();
    });
    await pumpDetail(tester, cubit);
    await tester.ensureVisible(find.byKey(const Key('group-part-claim-3')));
    await tester.tap(find.byKey(const Key('group-part-claim-3')));
    await tester.pump();
    owner.currentOwnerId = otherId;
    pending.complete(Right(repo.group.part(3)!));
    await tester.pump();
    await tester.pump();
    expect(cubit.state.groups, isEmpty);
    expect(find.text('Owner Name'), findsNothing);
  });
}
