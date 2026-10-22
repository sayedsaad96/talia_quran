import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_legacy_resume_recovery.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_legacy_resume_recovery_panel.dart';

void main() {
  testWidgets(
    'cancel keeps the choice recoverable and confirmation sends only the explicit split',
    (tester) async {
      late SharedPreferences prefs;
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      });
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = const FixedRecordOwnerProvider('child');
      final choices = <({bool whole, int? size})>[];
      final state = KidsModeSplitChoiceRequired(
        KidsLegacyResumeRecoveryTicket(
          ownerId: 'child',
          lease: barrier.capture(),
          surahId: 67,
          verifiedAyahCount: 30,
          defaultStageSize: 3,
          checkpointAyah: 3,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: KidsLegacyResumeRecoveryPanel(
              state: state,
              onRecover: ({required whole, stageSize}) async =>
                  choices.add((whole: whole, size: stageSize)),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('kids-legacy-recovery-choose')),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(choices, isEmpty);
      await tester.tap(
        find.byKey(const ValueKey('kids-legacy-recovery-choose')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('kids-split-size-4')));
      await tester.ensureVisible(
        find.byKey(const ValueKey('kids-split-confirm')),
      );
      await tester.tap(find.byKey(const ValueKey('kids-split-confirm')));
      await tester.pumpAndSettle();
      expect(choices, [(whole: false, size: 4)]);
      expect(tester.takeException(), isNull);
    },
  );
}
