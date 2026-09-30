import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_reader_session_bar.dart';

class _MockKhatmahCubit extends Mock implements KhatmahCubit {}

void main() {
  testWidgets('never shows page 0 when browsing outside the wird', (
    tester,
  ) async {
    final plan = KhatmahPlan(
      id: 'p',
      title: KhatmahPlan.defaultTitle,
      targetPagesPerDay: 5,
      targetDays: 121,
      startDate: DateTime(2026, 1, 1),
      expectedEndDate: DateTime(2026, 5, 1),
    );
    final state = KhatmahActive(plan: plan, wirdStartPage: 1, wirdEndPage: 5);
    final cubit = _MockKhatmahCubit();
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.displayDate).thenReturn(DateTime(2026, 1, 1));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: KhatmahReaderSessionBar(cubit: cubit, currentPage: 200),
        ),
      ),
    );

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(
      find.text(l10n.khatmahPageOfOfTodaySWird('1', '0', '5')),
      findsOneWidget,
    );
    expect(
      find.text(l10n.khatmahPageOfOfTodaySWird('0', '0', '5')),
      findsNothing,
    );
  });
}
