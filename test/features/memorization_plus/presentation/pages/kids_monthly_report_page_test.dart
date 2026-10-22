import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_monthly_report.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_monthly_report_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_monthly_report_view.dart';

void main() {
  final start = DateTime(2026, 10, 1);
  final end = DateTime(2026, 10, 30);

  final filled = KidsMonthlyReport(
    periodStart: start,
    periodEnd: end,
    sessions: 12,
    activeDays: 8,
    newAyahs: 5,
    reviews: 4,
    sessionsWithHints: 2,
    completedSurahIds: const [112],
    needsSupport: const [(surahId: 112, ayahNumber: 2)],
  );
  final empty = KidsMonthlyReport(periodStart: start, periodEnd: end);

  final png = Uint8List.fromList([1, 2, 3]);

  Future<void> pump(
    WidgetTester tester,
    KidsMonthlyReport report, {
    Future<void> Function(Uint8List, String, String)? onShare,
    Future<void> Function(Uint8List, String)? onPdf,
    Locale locale = const Locale('en'),
    bool historyComplete = true,
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: KidsMonthlyReportPage(
          report: report,
          historyComplete: historyComplete,
          captureView: (view, context) async => png,
          onShareImage: onShare ?? (_, _, _) async {},
          onSavePdf: onPdf ?? (_, _) async {},
        ),
      ),
    );
  }

  testWidgets('an empty month says so and offers no export', (tester) async {
    await pump(tester, empty);

    expect(find.text('No sessions this month'), findsOneWidget);
    expect(find.byKey(const ValueKey('monthly-report-share')), findsNothing);
    expect(find.byKey(const ValueKey('monthly-report-pdf')), findsNothing);
    expect(find.byKey(const ValueKey('monthly-report-note')), findsNothing);
  });

  testWidgets('a filled report shows counts, surahs and ayahs', (tester) async {
    await pump(tester, filled);

    expect(find.text('12 sessions'), findsOneWidget);
    expect(find.text('8 active days'), findsOneWidget);
    expect(find.text('5 new ayahs'), findsOneWidget);
    expect(find.text('4 reviews'), findsOneWidget);
    expect(find.text('Surahs completed'), findsOneWidget);
    expect(find.text('Ayahs that need support'), findsOneWidget);
    expect(find.text('No sessions this month'), findsNothing);
  });

  testWidgets('an incomplete history shows a notice and hides surahs', (
    tester,
  ) async {
    await pump(tester, filled, historyComplete: false);

    expect(
      find.byKey(const ValueKey('monthly-report-incomplete')),
      findsOneWidget,
    );
    expect(find.text('Surahs completed'), findsNothing);
    expect(find.text('12 sessions'), findsOneWidget);
  });

  testWidgets('a complete history has no notice', (tester) async {
    await pump(tester, filled);

    expect(
      find.byKey(const ValueKey('monthly-report-incomplete')),
      findsNothing,
    );
    expect(find.text('Surahs completed'), findsOneWidget);
  });

  testWidgets('the capture canvas holds a tall report at text scale 1.5', (
    tester,
  ) async {
    final tall = KidsMonthlyReport(
      periodStart: start,
      periodEnd: end,
      sessions: 12,
      activeDays: 8,
      newAyahs: 5,
      reviews: 4,
      sessionsWithHints: 2,
      completedSurahIds: [for (var i = 1; i <= 15; i++) i],
      needsSupport: [
        for (var i = 1; i <= 10; i++) (surahId: i, ayahNumber: i),
      ],
    );
    tester.view.physicalSize = kidsReportCanvasSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final canvasKey = GlobalKey();
    final viewKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Align(
          alignment: Alignment.topLeft,
          child: KidsReportCaptureCanvas(
            key: canvasKey,
            child: KidsMonthlyReportView(
              key: viewKey,
              report: tall,
              note: List.filled(200, 'n').join(),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final canvas = tester.getRect(find.byKey(canvasKey));
    final view = tester.getRect(find.byKey(viewKey));
    expect(canvas.size, kidsReportCanvasSize);
    expect(view.top, greaterThanOrEqualTo(canvas.top - 0.5));
    expect(view.bottom, lessThanOrEqualTo(canvas.bottom + 0.5));
    expect(view.left, greaterThanOrEqualTo(canvas.left - 0.5));
    expect(view.right, lessThanOrEqualTo(canvas.right + 0.5));
  });

  testWidgets('the note is limited to 200 characters', (tester) async {
    await pump(tester, filled);

    await tester.enterText(
      find.byKey(const ValueKey('monthly-report-note')),
      List.filled(260, 'a').join(),
    );
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('monthly-report-note')),
    );
    expect(field.controller!.text.length, 200);
  });

  testWidgets('share hands the captured image and a name to the sharer', (
    tester,
  ) async {
    Uint8List? bytes;
    String? name;
    String? text;
    await pump(
      tester,
      filled,
      onShare: (b, n, t) async {
        bytes = b;
        name = n;
        text = t;
      },
    );

    await tester.tap(find.byKey(const ValueKey('monthly-report-share')));
    await tester.pumpAndSettle();

    expect(bytes, png);
    expect(name, endsWith('.png'));
    expect(text, 'Talia monthly report');
  });

  testWidgets('save PDF hands the captured image to the pdf writer', (
    tester,
  ) async {
    Uint8List? bytes;
    String? name;
    await pump(
      tester,
      filled,
      onPdf: (b, n) async {
        bytes = b;
        name = n;
      },
    );

    await tester.tap(find.byKey(const ValueKey('monthly-report-pdf')));
    await tester.pumpAndSettle();

    expect(bytes, png);
    expect(name, endsWith('.pdf'));
  });
}
