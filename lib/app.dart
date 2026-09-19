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
import 'features/prayer_companion/application/prayer_companion_controller.dart';
import 'features/quran/presentation/cubits/quran_audio_player_cubit.dart';
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
      unawaited(getIt<TaliaNotificationService>().clearBadge());
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
        locale: const Locale('ar'),
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
      notificationService.onNotificationResponse = _handleNotificationResponse;

      // Theme, locale, and profile are already loaded during AppInitializer.
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
        BlocProvider.value(value: getIt<QuranAudioPlayerCubit>()),
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
                  lookupAppLocalizations(
                    locale,
                  ).accountSwitchOfflineDataDiscarded,
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
                    builder: (context, child) {
                      final media = MediaQuery.of(context);
                      return MediaQuery(
                        data: media.copyWith(
                          textScaler: media.textScaler.clamp(
                            minScaleFactor: 0.85,
                            maxScaleFactor: 1.35,
                          ),
                        ),
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
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

  /// Foreground notification tap: the companion controller persists any
  /// companion command first, then navigation follows its outcome. Legacy
  /// routing keeps flowing through [_openNotification]; companion (`pc1`)
  /// payloads are a no-op there because they never start with '/'.
  Future<void> _handleNotificationResponse(
    NotificationResponseEvent event,
  ) async {
    if (!mounted || !AppInitializer.isInitialized) return;
    final outcome = await getIt<PrayerCompanionController>().handle(event);
    if (!mounted) return;
    AppRouter.router.go(outcome.route);
  }

  /// Cold start: dependencies are ready here, so the pending launch goes
  /// through the same controller — a companion action is written once during
  /// startup, then the route is applied.
  Future<void> _applyLaunchNavigation(
    TaliaNotificationService notificationService,
  ) async {
    if (!mounted) return;
    final isFirstTime =
        getIt<SharedPreferences>().getBool(
          LaunchDestination.firstTimePreferenceKey,
        ) ??
        true;
    final pending = notificationService.takePendingLaunch();
    if (pending == null) {
      if (!isFirstTime) return;
      AppRouter.router.go(AppRoutes.onboarding);
      return;
    }
    final event = NotificationResponseEvent(
      payload: pending.payload,
      actionId: pending.actionId,
    );
    if (isFirstTime) {
      // First-time users always go to onboarding; no notification response
      // (companion or legacy) is applied before onboarding completes.
      AppRouter.router.go(AppRoutes.onboarding);
      return;
    }
    final outcome = await getIt<PrayerCompanionController>().handle(event);
    if (!mounted) return;
    if (outcome.route != AppRoutes.home) {
      AppRouter.router.go(outcome.route);
    }
  }

  void _openNotification(String payload) {
    if (!mounted || payload.isEmpty || !payload.startsWith('/')) return;
    AppRouter.router.go(payload);
  }
}
