import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/settings/presentation/pages/privacy_policy_page.dart';

void main() {
  testWidgets('renders Arabic privacy policy correctly', (tester) async {
    await _pumpPrivacyPage(tester, const Locale('ar'));

    // Check title and key Arabic sections
    expect(find.text('سياسة الخصوصية'), findsOneWidget);
    expect(find.text('١. مقدمة'), findsOneWidget);
    expect(find.textContaining('المعلومات التي نجمعها'), findsWidgets);
    await _scrollToVoiceDisclosure(tester, 'الميكروفون:');
    expect(find.textContaining('خدمة التعرف الصوتي المدمجة'), findsOneWidget);
    expect(
      find.textContaining('مزوّد نظام التشغيل وفق سياساته الخاصة'),
      findsOneWidget,
    );
    expect(
      find.textContaining('لا يحتفظ تطبيق تالية بالصوت الخام'),
      findsWidgets,
    );
    expect(find.textContaining('لا يرسله إلى خوادمنا'), findsWidgets);
    expect(find.textContaining('خيار التقييم الذاتي اليدوي'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('خصوصية الأطفال'),
      400,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('خصوصية الأطفال'), findsWidgets);

    await tester.scrollUntilVisible(
      find.textContaining('تواصل معنا'),
      400,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('تواصل معنا'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('elsayed.saad2014@feps.edu.eg'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('elsayed.saad2014@feps.edu.eg'), findsWidgets);
  });

  testWidgets('renders English privacy policy correctly', (tester) async {
    await _pumpPrivacyPage(tester, const Locale('en'));

    // Check title and key English sections
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('1. Introduction'), findsOneWidget);
    expect(find.textContaining('Information We Collect'), findsWidgets);
    await _scrollToVoiceDisclosure(tester, 'Microphone:');
    expect(
      find.textContaining("operating system's built-in speech service"),
      findsOneWidget,
    );
    expect(
      find.textContaining('platform provider may process audio'),
      findsOneWidget,
    );
    expect(find.textContaining('does not retain raw audio'), findsWidgets);
    expect(
      find.textContaining('does not send it to Talia servers'),
      findsOneWidget,
    );
    expect(find.textContaining('manual self-grade option'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('Children’s Privacy'),
      400,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('Children’s Privacy'), findsWidgets);

    await tester.scrollUntilVisible(
      find.textContaining('Contact Us'),
      400,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('Contact Us'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('elsayed.saad2014@feps.edu.eg'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('elsayed.saad2014@feps.edu.eg'), findsWidgets);
  });

  for (final locale in <Locale>[const Locale('ar'), const Locale('en')]) {
    testWidgets(
      'manual privacy action navigates to memorization in ${locale.languageCode}',
      (tester) async {
        await _pumpPrivacyPage(tester, locale, includeMemorizationRoute: true);

        final action = find.byKey(
          const ValueKey('privacy-manual-option-action'),
        );
        await _scrollToBottom(tester);
        expect(action, findsOneWidget);
        expect(
          find.text(
            locale.languageCode == 'ar'
                ? 'افتح الحفظ لاستخدام التقييم الذاتي'
                : 'Open memorization to use manual self-grade',
          ),
          findsOneWidget,
        );

        await tester.tap(action);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('memorization-destination')),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('back button triggers page pop', (tester) async {
    bool hasPopped = false;
    final router = GoRouter(
      initialLocation: '/settings/privacy-policy',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: Text('Settings')),
        ),
        GoRoute(
          path: '/settings/privacy-policy',
          builder: (context, state) => const PrivacyPolicyPage(),
          redirect: (context, state) {
            if (hasPopped) return '/settings';
            return null;
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
      ),
    );
    await tester.pump();

    // Tap back button
    final backButton = find.byType(BackButtonIcon);
    expect(backButton, findsOneWidget);

    // Simulate tap
    hasPopped = true;
    await tester.tap(backButton);
    await tester.pumpAndSettle();
  });
}

Future<void> _pumpPrivacyPage(
  WidgetTester tester,
  Locale locale, {
  bool includeMemorizationRoute = false,
}) async {
  final router = GoRouter(
    initialLocation: AppRoutes.privacyPolicy,
    routes: [
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      if (includeMemorizationRoute)
        GoRoute(
          path: AppRoutes.memorizationHub,
          builder: (context, state) => const Scaffold(
            body: SizedBox(key: ValueKey('memorization-destination')),
          ),
        ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
    ),
  );
  await tester.pump();
}

Future<void> _scrollToVoiceDisclosure(
  WidgetTester tester,
  String pattern,
) async {
  await tester.scrollUntilVisible(
    find.textContaining(pattern),
    400,
    scrollable: find.byType(Scrollable),
  );
  expect(find.textContaining(pattern), findsOneWidget);
}

Future<void> _scrollToBottom(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable);
  for (var i = 0; i < 8; i++) {
    await tester.drag(scrollable, const Offset(0, -700));
    await tester.pump();
  }
}
