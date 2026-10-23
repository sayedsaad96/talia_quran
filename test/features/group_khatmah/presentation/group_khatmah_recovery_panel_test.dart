import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/group_khatmah/domain/repositories/group_khatmah_repository.dart';
import 'package:talia_quran/features/group_khatmah/presentation/cubits/group_khatmah_cubit.dart';
import 'package:talia_quran/features/group_khatmah/presentation/pages/group_khatmah_list_page.dart';
import 'group_khatmah_detail_page_test.dart' as fixture;

void main() {
  testWidgets(
    'offline recovery shows request without exposing unvalidated roster',
    (tester) async {
      final repository = fixture.FakeGroupRepository(fixture.sampleGroup())
        ..refreshFailure = const NetworkFailure()
        ..failed = [
          const GroupFailedOperation(
            operationId: 'failed-create',
            action: 'create',
          ),
        ];
      final cubit = GroupKhatmahCubit(
        repository: repository,
        owner: const FixedRecordOwnerProvider(fixture.ownerId),
      );
      addTearDown(() async {
        await cubit.close();
        await repository.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GroupKhatmahListPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shared reading'), findsNothing);
      expect(find.text('Owner Name'), findsNothing);
      await tester.tap(find.byKey(const Key('group-discard-failed-create')));
      await tester.pumpAndSettle();
      expect(repository.discardCalls, 0);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(repository.discardCalls, 1);
      expect(
        find.byKey(const Key('group-discard-failed-create')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
