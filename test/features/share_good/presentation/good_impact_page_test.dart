import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/share_good/domain/entities/good_impact.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/domain/services/invite_target_labeler.dart';
import 'package:talia_quran/features/share_good/presentation/cubits/good_impact_cubit.dart';
import 'package:talia_quran/features/share_good/presentation/pages/good_impact_page.dart';

class MockImpactCubit extends Mock implements GoodImpactCubit {}

class FakeQuran implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'shows aggregates, opted-in name and separate invitation sections',
    (tester) async {
      final now = DateTime.now();
      final impact = GoodImpact(
        invites: [
          InviteImpactSummary(
            target: const QuranPageInviteTarget(1),
            status: InviteLifecycleStatus.active,
            expiresAt: now.add(const Duration(days: 1)),
            opens: 2,
            starts: 1,
            completions: 1,
          ),
          InviteImpactSummary(
            target: const QuranPageInviteTarget(2),
            status: InviteLifecycleStatus.expired,
            expiresAt: now.subtract(const Duration(days: 1)),
            opens: 2,
            starts: 1,
            completions: 1,
          ),
        ],
        responses: 2,
        completions: 1,
        downstreamReach: 3,
        acknowledgements: [
          NamedAcknowledgement(
            target: const QuranPageInviteTarget(1),
            visibleName: 'Opted In',
            completedAt: now,
          ),
        ],
        fetchedAt: now,
      );
      final ready = GoodImpactReady(
        ownerId: 'a',
        impact: impact,
        milestones: const {},
        hasNew: true,
        fingerprint: 'hash',
      );
      final cubit = MockImpactCubit();
      when(() => cubit.state).thenReturn(ready);
      when(
        () => cubit.stream,
      ).thenAnswer((_) => const Stream<GoodImpactState>.empty());
      when(() => cubit.isCurrent(ready)).thenReturn(true);
      when(() => cubit.refresh(force: true)).thenAnswer((_) async {});
      when(() => cubit.markSeen()).thenAnswer((_) async {});
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GoodImpactPage(
            cubit: cubit,
            labeler: InviteTargetLabeler(FakeQuran()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(GoodImpactPage)),
      );
      expect(find.text(l10n.goodImpactResponses(2)), findsOneWidget);
      expect(find.text('Opted In'), findsOneWidget);
      expect(find.text(l10n.goodImpactActive), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(l10n.goodImpactRecentlyExpired),
        200,
      );
      expect(find.text(l10n.goodImpactRecentlyExpired), findsOneWidget);
      verify(() => cubit.markSeen()).called(1);
    },
  );
}
