import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_page_confirmation.dart';

void main() {
  final today = DateTime(2026, 10, 25);
  // Nothing read yet at four pages a day: today's wird is pages 1-4, so the
  // last page (4) needs an explicit confirmation.
  final plan = KhatmahPlan(
    id: 'p',
    title: KhatmahPlan.defaultTitle,
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: today,
    expectedEndDate: today.add(const Duration(days: 150)),
  );

  Future<void> pump(WidgetTester tester, KhatmahState state) =>
      tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: KhatmahPageConfirmation(
              cubit: _FakeKhatmahCubit(state, today),
              pageNumber: 4,
              enabled: true,
              onConfirm: () async {},
            ),
          ),
        ),
      );

  const button = Key('khatmah_confirm_page_button');

  testWidgets('shows the button for the last page of the wird', (
    tester,
  ) async {
    await pump(
      tester,
      KhatmahActive(plan: plan, wirdStartPage: 1, wirdEndPage: 4),
    );
    expect(find.byKey(button), findsOneWidget);
  });

  testWidgets('a failed save keeps the button while the plan is active', (
    tester,
  ) async {
    await pump(
      tester,
      KhatmahProgressFailure(
        plan: plan,
        pageNumber: 3,
        source: KhatmahReadingSource.digital,
        error: 'storage',
      ),
    );
    expect(find.byKey(button), findsOneWidget);
  });

  testWidgets('a failure without a plan, or a paused plan, shows nothing', (
    tester,
  ) async {
    await pump(
      tester,
      const KhatmahProgressFailure(
        plan: null,
        pageNumber: 3,
        source: KhatmahReadingSource.digital,
        error: 'storage',
      ),
    );
    expect(find.byKey(button), findsNothing);
    await pump(
      tester,
      KhatmahProgressFailure(
        plan: plan.pause(at: today),
        pageNumber: 3,
        source: KhatmahReadingSource.digital,
        error: 'storage',
      ),
    );
    expect(find.byKey(button), findsNothing);
  });
}

class _FakeKhatmahCubit extends Cubit<KhatmahState> implements KhatmahCubit {
  _FakeKhatmahCubit(super.initialState, this.displayDate);

  @override
  final DateTime displayDate;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
