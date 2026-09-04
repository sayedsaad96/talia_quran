import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatm_dua_datasource.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_khatm_dua_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatm_dua_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatm_dua_page.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_completion_page.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_dashboard_page.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_setup_page.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_dedication_form.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_hero_card.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_progress_gauge.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_reader_session_bar.dart';

import 'pages/khatmah_dashboard_page_test.dart' as dashboard;
import 'pages/khatmah_setup_page_test.dart' as setup;

Widget localized(Widget child, String locale, {double scale = 1}) =>
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    );

void main() {
  final plan = KhatmahPlan(
    id: 'localization',
    title: 'Test plan',
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 6, 1),
    completedPages: {1, 2},
    dedication: const KhatmahDedication(
      isDedicated: true,
      recipientName: 'فاطمة',
      relationship: 'والد / والدة',
      condition: DedicationCondition.deceased,
      customNote: 'My personal note',
    ),
  );

  void narrow(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  test('real Dua is registered without borrowing corpus approval', () {
    final manifest =
        jsonDecode(File('assets/data/content_manifest.json').readAsStringSync())
            as Map;
    final entries = (manifest['items'] as List).cast<Map>();
    final dua = entries.where((e) => e['path'] == 'assets/data/khatm_dua.json');
    expect(dua, hasLength(1));
    final entry = dua.single;
    expect(entry['reviewStatus'], 'pendingReview');
    expect(entry['reviewer'], isNull);
    expect(entry['sourceLocator'], isNull);
    expect(entry['pendingReason'], isNotEmpty);
    expect(
      entry['sha256'],
      sha256
          .convert(File(entry['path'] as String).readAsBytesSync())
          .toString(),
    );
    final data =
        jsonDecode(File(entry['path'] as String).readAsStringSync()) as Map;
    expect(data['reviewStatus'], 'pendingReview');
    expect(
      data['dedicationFeatureReview']['authority'],
      'projectOwnerReportedScholarConsultation',
    );
    expect(data['dedicationFeatureReview']['scholarIdentity'], isNull);
    expect('${data['source']} ${data['sourceNote']}', isNot(contains('مأثور')));
    for (final item in entries.where((e) => e['path'] != entry['path'])) {
      expect(item['reviewStatus'], 'approved');
      expect(item['reviewDate'], '2026-08-31');
    }
  });

  for (final locale in ['ar', 'en']) {
    final ar = locale == 'ar';
    testWidgets('$locale Home exposes no-plan and paused actions at 2x', (
      tester,
    ) async {
      narrow(tester);
      for (final paused in [false, true]) {
        await tester.pumpWidget(
          localized(
            Scaffold(
              body: KhatmahHeroCard(
                plan: paused
                    ? plan.copyWith(status: KhatmahStatus.paused)
                    : null,
                isDark: false,
              ),
            ),
            locale,
            scale: 2,
          ),
        );
        expect(
          find.text(
            paused
                ? (ar ? 'استئناف' : 'Resume')
                : (ar ? 'ابدأ ختمة' : 'Start Khatmah'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('$locale legacy relationship remains visible and unchanged', (
      tester,
    ) async {
      KhatmahDedication? changed;
      await tester.pumpWidget(
        localized(
          Scaffold(
            body: SingleChildScrollView(
              child: KhatmahDedicationForm(
                initialDedication: const KhatmahDedication(
                  isDedicated: true,
                  relationship: 'الأم',
                ),
                onChanged: (value) => changed = value,
              ),
            ),
          ),
          locale,
        ),
      );
      expect(find.text(ar ? 'الأم' : 'Mother'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('khatmah_dedication_recipient_name')),
        'مريم',
      );
      expect(changed?.relationship, 'الأم');
    });

    testWidgets('$locale Home localizes active range and dedication', (
      tester,
    ) async {
      await tester.pumpWidget(
        localized(
          Scaffold(body: KhatmahHeroCard(plan: plan, isDark: false)),
          locale,
        ),
      );
      expect(
        find.textContaining(ar ? 'ورد اليوم' : 'Today: pages'),
        findsOneWidget,
      );
      expect(
        find.textContaining(ar ? 'إهداء إلى: فاطمة' : 'Dedicated to: فاطمة'),
        findsOneWidget,
      );
    });

    testWidgets('$locale gauge announces empty partial and complete coverage', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      narrow(tester);
      for (final count in [0, 2, 604]) {
        await tester.pumpWidget(
          localized(
            Scaffold(
              body: KhatmahProgressGauge(
                plan: plan.copyWith(
                  completedPages: {for (var p = 1; p <= count; p++) p},
                ),
              ),
            ),
            locale,
            scale: 2,
          ),
        );
        expect(
          find.bySemanticsLabel(
            RegExp(ar ? 'تقدم الختمة' : 'Khatmah progress'),
          ),
          findsOneWidget,
        );
        final value = tester
            .getSemantics(
              find.bySemanticsLabel(
                RegExp(ar ? 'تقدم الختمة' : 'Khatmah progress'),
              ),
            )
            .value;
        expect(value, contains(ar ? 'من ٦٠٤ صفحة' : 'of 604 pages'));
        expect(
          value,
          contains(
            count == 0
                ? '0.0'
                : count == 2
                ? '0.3'
                : '100.0',
          ),
        );
        expect(tester.takeException(), isNull);
      }
      semantics.dispose();
    });

    testWidgets('$locale setup and legacy dedication remain usable at 2x', (
      tester,
    ) async {
      narrow(tester);
      final cubit = KhatmahSetupCubit(setup.MockCreateKhatmahUsecase());
      addTearDown(cubit.close);
      await tester.pumpWidget(
        localized(KhatmahSetupPage(cubit: cubit), locale, scale: 2),
      );
      expect(tester.takeException(), isNull);
      final toggle = find.byKey(const Key('khatmah_dedication_toggle'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text(ar ? 'متوفى' : 'Deceased'), findsOneWidget);
      expect(find.text(ar ? 'حي' : 'Living'), findsOneWidget);
      expect(
        find.textContaining(
          ar ? 'المتوفى أولى' : 'Deceased recipients are preferred',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      KhatmahDedication? changed;
      await tester.pumpWidget(
        localized(
          Scaffold(
            body: SingleChildScrollView(
              child: KhatmahDedicationForm(
                initialDedication: plan.dedication,
                onChanged: (value) => changed = value,
              ),
            ),
          ),
          locale,
          scale: 2,
        ),
      );
      expect(find.text(ar ? 'والد / والدة' : 'Parent'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('khatmah_dedication_recipient_name')),
        'مريم',
      );
      expect(changed?.relationship, 'والد / والدة');
      expect(changed?.condition, DedicationCondition.deceased);
      expect(changed?.customNote, 'My personal note');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '$locale completion retains neutral dedication without gendered prayer',
      (tester) async {
        narrow(tester);
        for (final condition in [
          DedicationCondition.alive,
          DedicationCondition.deceased,
        ]) {
          final completed = plan.copyWith(
            status: KhatmahStatus.completed,
            completedPages: {for (var p = 1; p <= 604; p++) p},
            dedication: KhatmahDedication(
              isDedicated: true,
              recipientName: 'فاطمة',
              relationship: 'والد / والدة',
              customNote: 'My personal note',
              condition: condition,
            ),
          );
          final result = KhatmahReadingResult(
            plan: completed,
            newlyCompletedPages: const {604},
            historyEntry: KhatmahHistoryEntry(
              id: plan.id,
              khatmahNumber: 1,
              title: plan.title,
              startDate: plan.startDate,
              completedDate: DateTime(2026, 1, 5),
              totalDays: 5,
            ),
          );
          await tester.pumpWidget(
            localized(
              KhatmahCompletionPage(completion: result, enableConfetti: false),
              locale,
              scale: 2,
            ),
          );
          expect(
            find.text(
              ar
                  ? 'مبارك ختم القرآن الكريم'
                  : 'Congratulations on completing the Quran',
            ),
            findsOneWidget,
          );
          expect(
            find.textContaining(
              ar ? 'إهداء إلى: فاطمة' : 'Dedicated to: فاطمة',
            ),
            findsOneWidget,
          );
          expect(find.textContaining('لِعَبْدِكَ'), findsNothing);
          expect(find.textContaining('My personal note'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      '$locale Dua keeps Arabic text and pending provenance, copies no template',
      (tester) async {
        narrow(tester);
        final cubit = KhatmDuaCubit(GetKhatmDuaUsecase(KhatmDuaDatasource()));
        addTearDown(cubit.close);
        await tester.runAsync(cubit.load);
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.pumpWidget(
          localized(
            KhatmDuaPage(cubit: cubit, dedication: plan.dedication),
            locale,
            scale: 2,
          ),
        );
        expect(
          find.text(
            ar
                ? 'دعاء عام مقترح بعد الختم'
                : 'Suggested general supplication after Khatmah',
          ),
          findsWidgets,
        );
        expect(
          find.textContaining(
            ar
                ? 'مراجعة النص والمصدر معلّقة'
                : 'Text and source review pending',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('مأثور'), findsNothing);
        expect(
          find.textContaining('اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('khatm_dua_copy_button')));
        await tester.pump();
        expect(copied, contains('فاطمة'));
        expect(copied, isNot(contains('لِعَبْدِكَ')));
        expect(copied, isNot(contains('My personal note')));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('$locale physical logger announces inclusive range at 2x', (
      tester,
    ) async {
      narrow(tester);
      final get = dashboard.MockGetActiveKhatmahUsecase();
      when(() => get()).thenAnswer((_) async => plan);
      final cubit = KhatmahCubit(
        get,
        dashboard.MockRecordKhatmahReadingUsecase(),
        dashboard.MockPauseResumeKhatmahUsecase(),
        dashboard.MockDeleteKhatmahUsecase(),
      );
      addTearDown(cubit.close);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        localized(KhatmahDashboardPage(cubit: cubit), locale, scale: 2),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final log = find.byKey(const Key('khatmah_dashboard_log_mushaf_button'));
      await tester.ensureVisible(log);
      await tester.tap(log);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('khatmah_dashboard_mushaf_page_input')),
        ar ? '٨' : '8',
      );
      await tester.pump();
      expect(
        find.bySemanticsLabel(
          RegExp(
            ar
                ? 'سيتم تسجيل الصفحات من ٣ إلى ٨'
                : 'Record pages 3 to 8 inclusive',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        localized(
          Scaffold(body: KhatmahReaderSessionBar(cubit: cubit)),
          locale,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(ar ? 'ورد اليوم' : "today's wird"),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
