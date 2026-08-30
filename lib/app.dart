import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/l10n/app_localizations.dart';
import 'core/di/injection.dart';
import 'core/l10n/locale_cubit.dart';
import 'core/router/app_router.dart';
import 'core/router/launch_destination.dart';

import 'core/services/app_session_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_scheduler.dart';
import 'core/services/app_initializer.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/settings/presentation/cubits/profile_cubit.dart';

/// Notifier that signals when [AppInitializer] has finished.
/// Listened to by [TaliaApp] to rebuild from the splash-only shell
/// into the full BlocProvider tree + GoRouter.
final ValueNotifier<bool> appInitializedNotifier = ValueNotifier<bool>(false);
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class TaliaApp extends StatefulWidget {
  const TaliaApp({super.key});

  @override
  State<TaliaApp> createState() => _TaliaAppState();
}

class _TaliaAppState extends State<TaliaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appInitializedNotifier.addListener(_onInitialized);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appInitializedNotifier.removeListener(_onInitialized);
    super.dispose();
  }

  void _onInitialized() {
    if (appInitializedNotifier.value && mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only process lifecycle events after initialization.
    if (!AppInitializer.isInitialized) return;

    if (state == AppLifecycleState.resumed) {
      final currentLocale = getIt<LocaleCubit>().state;
      final l10n = lookupAppLocalizations(currentLocale);
      unawaited(getIt<NotificationScheduler>().refreshNotifications(l10n));
      getIt<AuthCubit>().resyncOnResume();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveCurrentLocation();
    }
  }

  void _saveCurrentLocation() {
    if (!AppInitializer.isInitialized) return;
    final location = AppRouter.router.routerDelegate.currentConfiguration.uri
        .toString();
    unawaited(getIt<AppSessionService>().saveLocation(location));
  }

  @override
  Widget build(BuildContext context) {
    // Before initialization, show a minimal app with only the splash route.
    if (!AppInitializer.isInitialized) {
      return MaterialApp.router(
        title: 'تالية',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: AppRouter.splashOnlyRouter,
      );
    }

    // After initialization, show the full app with all providers.
    return _buildFullApp();
  }

  bool _fullAppWired = false;

  Widget _buildFullApp() {
    // Wire up notification handler only once.
    if (!_fullAppWired) {
      _fullAppWired = true;
      final notificationService = getIt<TaliaNotificationService>();
      notificationService.onPayloadReceived = _openNotification;

      // Load persisted theme/locale/profile once. The cubits below are
      // shared getIt singletons exposed via BlocProvider.value so the
      // widget tree never closes them.
      getIt<ThemeCubit>().loadTheme();
      getIt<LocaleCubit>().loadLocale();
      getIt<ProfileCubit>().loadProfile();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyLaunchNavigation(notificationService);
      });
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider.value(value: getIt<LocaleCubit>()),
        BlocProvider.value(value: getIt<ProfileCubit>()),
        BlocProvider.value(value: getIt<AuthCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordRecoveryDetected) {
            AppRouter.router.go(AppRoutes.updatePassword);
          }
          if (state is AuthAccountDataDiscarded) {
            final locale = getIt<LocaleCubit>().state;
            rootScaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(
                  lookupAppLocalizations(locale).accountSwitchOfflineDataDiscarded,
                ),
              ),
            );
          }
        },
        child: BlocListener<LocaleCubit, Locale>(
          listener: (_, locale) {
            unawaited(
              getIt<NotificationScheduler>().refreshNotifications(
                lookupAppLocalizations(locale),
              ),
            );
          },
          child: BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  return MaterialApp.router(
                    title: 'تالية',
                    debugShowCheckedModeBanner: false,
                    scaffoldMessengerKey: rootScaffoldMessengerKey,
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
      ),
    );
  }

  void _applyLaunchNavigation(TaliaNotificationService notificationService) {
    if (!mounted) return;
    final isFirstTime =
        getIt<SharedPreferences>().getBool(
          LaunchDestination.firstTimePreferenceKey,
        ) ??
        true;
    final pending = notificationService.takePendingLaunch();
    final location = LaunchDestination.resolve(
      isFirstTime: isFirstTime,
      payload: pending?.payload,
      actionId: pending?.actionId,
    );
    if (location != AppRoutes.home) {
      AppRouter.router.go(location);
    }
  }

  void _openNotification(String payload) {
    if (!mounted || payload.isEmpty || !payload.startsWith('/')) return;
    AppRouter.router.go(payload);
  }
}
