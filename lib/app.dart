import 'dart:async';
import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/accessibility/clarity_mode.dart';
import 'core/l10n/app_localizations.dart';
import 'core/di/injection.dart';
import 'core/l10n/locale_cubit.dart';
import 'core/l10n/digit_material_localizations.dart';
import 'core/router/app_router.dart';
import 'features/memorization_plus/presentation/world/kids_world_phase_controller.dart';
import 'core/router/launch_destination.dart';

import 'core/services/app_session_service.dart';
import 'core/home_widget/home_widget_publisher.dart';
import 'core/home_widget/home_widget_launch_controller.dart';
import 'core/router/widget_deep_link.dart';
import 'core/experience/experience_feature_flags.dart';
import 'core/identity/account_data_barrier.dart';
import 'core/memorization/memorization_path_resolver.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_scheduler.dart';
import 'core/services/app_initializer.dart';
import 'core/utils/talia_logger.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/pure_black_cubit.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/prayer_companion/application/prayer_companion_controller.dart';
import 'features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'features/settings/presentation/cubits/profile_cubit.dart';
import 'features/app_update/presentation/cubits/app_update_cubit.dart';
import 'features/app_update/presentation/widgets/app_update_prompt_listener.dart';

/// Notifier that signals when [AppInitializer] has finished.
/// Listened to by [TaliaApp] to rebuild from the splash-only shell
/// into the full BlocProvider tree + GoRouter.
final ValueNotifier<bool> appInitializedNotifier = ValueNotifier<bool>(false);

/// Never notifies; stands in when no clarity controller is registered.
final ChangeNotifier _noClarityChanges = ChangeNotifier();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class TaliaApp extends StatefulWidget {
  const TaliaApp({super.key});

  @override
  State<TaliaApp> createState() => _TaliaAppState();
}

class _TaliaAppState extends State<TaliaApp> with WidgetsBindingObserver {
  HomeWidgetLaunchController? _widgetLaunch;
  int _widgetNavigationEpoch = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appInitializedNotifier.addListener(_onInitialized);
    if (!kIsWeb && Platform.isAndroid) {
      _widgetLaunch = HomeWidgetLaunchController(
        events: HomeWidget.widgetClicked,
        initial: HomeWidget.initiallyLaunchedFromHomeWidget,
        onOpen: (uri) => unawaited(_openHomeWidget(uri)),
      )..start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appInitializedNotifier.removeListener(_onInitialized);
    unawaited(_widgetLaunch?.dispose());
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
    getIt<AppUpdateCubit>().setForeground(state == AppLifecycleState.resumed);

    if (state == AppLifecycleState.resumed) {
      if (getIt.isRegistered<HomeWidgetPublisher>()) {
        unawaited(getIt<HomeWidgetPublisher>().refresh());
      }
      final currentLocale = getIt<LocaleCubit>().state;
      final l10n = lookupAppLocalizations(currentLocale);
      unawaited(getIt<NotificationScheduler>().refreshNotifications(l10n));
      unawaited(getIt<TaliaNotificationService>().clearBadge());
      getIt<AuthCubit>().resyncOnResume();
      if (getIt.isRegistered<KidsWorldPhaseController>() &&
          getIt.checkLazySingletonInstanceExists<KidsWorldPhaseController>()) {
        unawaited(getIt<KidsWorldPhaseController>().refresh());
      }
      unawaited(
        getIt<AppUpdateCubit>().checkForUpdate(canPrompt: _isCalmUpdateSurface),
      );
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
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          DigitMaterialLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
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
        unawaited(_startPostInitializationTasks(notificationService));
      });
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider.value(value: getIt<PureBlackCubit>()),
        BlocProvider.value(value: getIt<LocaleCubit>()),
        BlocProvider.value(value: getIt<ProfileCubit>()),
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<QuranAudioPlayerCubit>()),
        BlocProvider.value(value: getIt<AppUpdateCubit>()),
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
                force: true,
              ),
            );
          },
          child: BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final pureBlack = context.watch<PureBlackCubit>().state;
                  final clarity = ClarityModeController.maybeInstance();
                  return ListenableBuilder(
                    listenable: clarity ?? _noClarityChanges,
                    builder: (context, _) {
                      final clarityOn = clarity?.isOn ?? false;
                      return MaterialApp.router(
                        onGenerateTitle: (context) =>
                            AppLocalizations.of(context).appName,
                        debugShowCheckedModeBanner: false,
                        scaffoldMessengerKey: rootScaffoldMessengerKey,
                        themeMode: themeMode,
                        theme: AppTheme.lightFor(highContrast: clarityOn),
                        darkTheme: pureBlack
                            ? AppTheme.oledFor(highContrast: clarityOn)
                            : AppTheme.darkFor(highContrast: clarityOn),
                        locale: locale,
                        supportedLocales: AppLocalizations.supportedLocales,
                        localizationsDelegates: const [
                          AppLocalizations.delegate,
                          DigitMaterialLocalizations.delegate,
                          GlobalMaterialLocalizations.delegate,
                          GlobalWidgetsLocalizations.delegate,
                          GlobalCupertinoLocalizations.delegate,
                        ],
                        routerConfig: AppRouter.router,
                        builder: (context, child) => ClarityTextScaleScope(
                          on: clarityOn,
                          child: AppUpdatePromptListener(
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _startPostInitializationTasks(
    TaliaNotificationService notificationService,
  ) async {
    await _applyLaunchNavigation(notificationService);
    _widgetLaunch?.activate();
    if (!mounted) return;
    if (getIt.isRegistered<HomeWidgetPublisher>()) {
      unawaited(getIt<HomeWidgetPublisher>().refresh());
    }
    getIt<AppUpdateCubit>().setForeground(
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    await getIt<AppUpdateCubit>().checkForUpdate(
      canPrompt: _isCalmUpdateSurface,
    );
  }

  bool _isCalmUpdateSurface() {
    if (!mounted) return false;
    final path = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    return path == AppRoutes.home || path == AppRoutes.settings;
  }

  Future<void> _openHomeWidget(Uri uri) async {
    if (!mounted || !AppInitializer.isInitialized) return;
    final epoch = ++_widgetNavigationEpoch;
    final prefs = getIt<SharedPreferences>();
    if (prefs.getBool(LaunchDestination.firstTimePreferenceKey) ?? true) return;
    try {
      final lease = AccountDataBarrier.forPreferences(prefs).capture();
      final profile = await getIt<MemorizationPathResolver>().currentProfile();
      lease.check();
      if (!mounted || epoch != _widgetNavigationEpoch) return;
      final enabled = getIt<ExperienceFlags>().isEnabled(
        ExperienceFeature.homeWidget,
      );
      var target = enabled && profile?.isAdult == true
          ? widgetDeepLinkDestination(uri)
          : AppRoutes.home;
      if (uri.path == '/prayer' && target != AppRoutes.home) {
        target = '$target&widgetTap=$epoch';
      }
      AppRouter.router.go(target);
    } on AccountDataUnavailableException {
      // Account transition owns navigation; discard the stale tap.
    } catch (error, stack) {
      // An unreadable profile must not strand the tap: fall back to home.
      TaliaLogger.w('Home widget tap could not resolve profile', error, stack);
      if (mounted && epoch == _widgetNavigationEpoch) {
        AppRouter.router.go(AppRoutes.home);
      }
    }
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
