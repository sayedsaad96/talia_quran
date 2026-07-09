import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_localizations.dart';
import 'core/di/injection.dart';
import 'core/l10n/locale_cubit.dart';
import 'core/router/app_router.dart';

import 'core/services/app_session_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_scheduler.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/settings/presentation/cubits/profile_cubit.dart';

class TaliaApp extends StatefulWidget {
  const TaliaApp({super.key});

  @override
  State<TaliaApp> createState() => _TaliaAppState();
}

class _TaliaAppState extends State<TaliaApp> with WidgetsBindingObserver {
  late final TaliaNotificationService _notificationService =
      getIt<TaliaNotificationService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationService.onPayloadReceived = _openNotification;
    AppRouter.router.routerDelegate.addListener(_saveCurrentLocation);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final payload = _notificationService.takePendingLaunchPayload();
      if (payload != null) {
        _openNotification(payload);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationService.onPayloadReceived = null;
    AppRouter.router.routerDelegate.removeListener(_saveCurrentLocation);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh notifications on resume to sync timezone/time
      final currentLocale = getIt<LocaleCubit>().state;
      final l10n = lookupAppLocalizations(currentLocale);
      getIt<NotificationScheduler>().refreshNotifications(l10n);
      // Parent Mode: self-healing resync of production data (review
      // records/daily plan/certificates/streak) on every resume, covering
      // any best-effort push that was missed while backgrounded/offline.
      getIt<AuthCubit>().resyncOnResume();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveCurrentLocation();
    }
  }

  void _openNotification(String payload) {
    if (!mounted || payload.isEmpty || !payload.startsWith('/')) return;
    AppRouter.router.go(payload);
  }

  void _saveCurrentLocation() {
    final location = AppRouter.router.routerDelegate.currentConfiguration.uri
        .toString();
    unawaited(getIt<AppSessionService>().saveLocation(location));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ThemeCubit>()..loadTheme()),
        BlocProvider(create: (_) => getIt<LocaleCubit>()..loadLocale()),
        BlocProvider(create: (_) => getIt<ProfileCubit>()..loadProfile()),
        // AuthCubit is a GetIt singleton — use value: so the framework does
        // not dispose it when this widget is torn down.
        BlocProvider.value(value: getIt<AuthCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordRecoveryDetected) {
            AppRouter.router.go(AppRoutes.updatePassword);
          }
        },
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return MaterialApp.router(
                  title: 'تالية',
                  debugShowCheckedModeBanner: false,
                  themeMode: themeMode,
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  routerConfig: AppRouter.router,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
