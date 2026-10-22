import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_offer_service.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_prompt_coordinator.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_companion/presentation/cubits/prayer_companion_cubit.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_authority.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_selection.dart';
import 'package:talia_quran/features/prayer_review/presentation/prayer_review_confirmation_bridge.dart';

class _Cubit extends Cubit<PrayerCompanionState>
    implements PrayerCompanionCubit {
  _Cubit(this.record, this.fail) : super(const PrayerCompanionIdle());
  final PrayerCompanionRecord record;
  final bool fail;
  @override
  Future<void> submit(PrayerCompanionCommand command) async {
    emit(
      fail
          ? PrayerCompanionFailure(StateError('failed'))
          : PrayerCompanionSuccess(record),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => getIt.reset());
  tearDown(() => getIt.reset());
  for (final scenario in [
    (fail: false, background: false),
    (fail: true, background: false),
    (fail: false, background: true),
  ]) {
    final fail = scenario.fail;
    testWidgets(
      'confirmation failure=$fail background=${scenario.background} requires foreground success',
      (tester) async {
        var lookups = 0;
        final now = DateTime(2026, 10, 20, 13);
        final occurrence = PrayerOccurrence(
          ownerId: 'owner',
          localDate: DateTime(2026, 10, 20),
          prayerKey: PrayerKey.dhuhr,
          scheduledAt: DateTime(2026, 10, 20, 12),
        );
        final record = PrayerCompanionRecord(
          occurrence: occurrence,
          status: PrayerCompanionStatus.confirmed,
          statusUpdatedAt: now,
          followUpCount: 0,
          createdAt: now,
          updatedAt: now,
        );
        final cubit = _Cubit(record, fail);
        await tester.runAsync(() async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final barrier = AccountDataBarrier.forPreferences(prefs)
            ..owner = const FixedRecordOwnerProvider('owner');
          PrayerReviewAuthority capture() =>
              PrayerReviewAuthority(ownerId: 'owner', lease: barrier.capture());
          final selected = PrayerReviewSelection(
            ownerId: 'owner',
            localDayKey: '2026-10-20',
            prayerKey: PrayerKey.dhuhr,
            scheduledAt: occurrence.scheduledAt.toUtc(),
            selectedAt: occurrence.scheduledAt.toUtc(),
            surahId: 1,
            startAyah: 1,
            endAyah: 3,
          );
          getIt.registerSingleton<ExperienceFlags>(
            ExperienceFlags((_) => true),
          );
          getIt.registerSingleton<PrayerReviewPromptCoordinator>(
            PrayerReviewPromptCoordinator(
              captureAuthority: capture,
              isEnabled: () => true,
              readAdultEligibility: () async => true,
              loadExisting: (_) async {
                lookups++;
                return PrayerReviewOffer(
                  selection: selected,
                  authority: capture(),
                );
              },
              claimPrompt: (_, _) async =>
                  selected.copyWith(promptConsumed: true),
              now: () => now,
            ),
          );
        });
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: FilledButton(
                  onPressed: () => submitPrayerCompanionWithReview(
                    context,
                    cubit,
                    occurrence,
                    PrayerCompanionCommand.confirm,
                  ),
                  child: const Text('confirm'),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.prayerReview,
              builder: (_, state) {
                expect(state.extra, occurrence);
                return const Scaffold(body: Text('reviewed'));
              },
            ),
          ],
        );
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        tester.binding.handleAppLifecycleStateChanged(
          scenario.background
              ? AppLifecycleState.paused
              : AppLifecycleState.resumed,
        );
        await tester.tap(find.text('confirm'));
        await tester.pumpAndSettle();
        final shouldOpen = !fail && !scenario.background;
        expect(
          find.text('reviewed'),
          shouldOpen ? findsOneWidget : findsNothing,
        );
        expect(lookups, shouldOpen ? 1 : 0);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        await cubit.close();
      },
    );
  }
}
