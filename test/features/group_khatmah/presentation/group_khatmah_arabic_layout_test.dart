import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/group_khatmah/presentation/cubits/group_khatmah_cubit.dart';
import 'group_khatmah_detail_page_test.dart' as fixture;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('active Arabic group fits 320dp at 2x text in $brightness', (
      tester,
    ) async {
      final repository = fixture.FakeGroupRepository(
        fixture.sampleGroup(pending: true),
      );
      final cubit = GroupKhatmahCubit(
        repository: repository,
        owner: const FixedRecordOwnerProvider(fixture.ownerId),
      )..start();
      addTearDown(() async {
        await cubit.close();
        await repository.dispose();
      });
      await fixture.pumpDetail(
        tester,
        cubit,
        locale: const Locale('ar'),
        brightness: brightness,
        size: const Size(320, 720),
        textScale: 2,
      );
      expect(find.byKey(const Key('group-part-30')), findsOneWidget);
      expect(find.byKey(const Key('group-part-pending-1')), findsOneWidget);
      final partContext = tester.element(find.byKey(const Key('group-part-1')));
      expect(Directionality.of(partContext), TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });
  }
}
