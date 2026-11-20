import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/talia_localization_delegates.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/domain/services/invite_target_labeler.dart';
import 'package:talia_quran/features/share_good/presentation/cubits/invite_preview_cubit.dart';
import 'package:talia_quran/features/share_good/presentation/pages/invite_preview_page.dart';

class _PreviewCubit extends Mock implements InvitePreviewCubit {}

void main() {
  const token = 'private-token';
  late _PreviewCubit cubit;

  setUp(() {
    cubit = _PreviewCubit();
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.load(any())).thenAnswer((_) async {});
  });

  Future<void> showPage(WidgetTester tester, Locale locale) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => BlocProvider<InvitePreviewCubit>.value(
            value: cubit,
            child: const InvitePreviewPage(token: token),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: taliaLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    testWidgets('ready invitation offers start without sign in: $locale', (
      tester,
    ) async {
      final invite = ResolvedInvite(
        token: token,
        target: const QuranSurahInviteTarget(18),
        moment: InviteMoment.beforeActivity,
        mode: InviteMode.personal,
        inviter: const InviterIdentity(mode: InviteIdentityMode.anonymous),
        status: InviteLifecycleStatus.active,
        expiresAt: DateTime(2030),
      );
      when(() => cubit.state).thenReturn(
        InvitePreviewReady(
          InviteSession(token: token, snapshot: invite),
          const InviteTargetLabel(
            title: 'Al-Kahf',
            startPage: 293,
            endPage: 304,
          ),
        ),
      );
      await showPage(tester, locale);
      expect(
        find.text(locale.languageCode == 'ar' ? 'ابدأ الآن' : 'Start now'),
        findsOneWidget,
      );
      expect(find.text(token), findsNothing);
      expect(find.textContaining('Sign in'), findsNothing);
      expect(find.textContaining('تسجيل الدخول'), findsNothing);
      expect(
        Directionality.of(tester.element(find.byType(FilledButton))),
        locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
      expect(
        tester.getSemantics(find.byType(FilledButton)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          label: locale.languageCode == 'ar' ? 'ابدأ الآن' : 'Start now',
        ),
      );
    });
  }

  testWidgets('offline retry loads the invite again', (tester) async {
    when(() => cubit.state).thenReturn(const InvitePreviewOffline());
    await showPage(tester, const Locale('ar'));
    await tester.tap(find.text('حاول مجدداً'));
    verify(() => cubit.load(token)).called(2);
  });
}
