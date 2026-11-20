import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations, GlobalMaterialLocalizations, MaterialLocalizationAr;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/accessibility/clarity_mode.dart';
import 'core/config/supabase_config.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/talia_localization_delegates.dart';
import 'core/di/injection.dart';
import 'core/l10n/locale_cubit.dart';
import 'core/l10n/digit_material_localizations.dart';
import 'core/router/app_router.dart';
import 'features/memorization_plus/presentation/world/kids_world_phase_controller.dart';
import 'core/router/launch_destination.dart';
import 'core/router/quran_audio_notification_controller.dart';
import 'core/services/quran_continuous_player_service.dart';

import 'core/services/app_session_service.dart';
import 'core/home_widget/home_widget_publisher.dart';
import 'core/home_widget/home_widget_launch_controller.dart';
import 'core/router/widget_deep_link.dart';
import 'core/router/widget_wird_route.dart';
import 'features/khatmah/domain/repositories/khatmah_repository.dart';
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
import 'features/share_good/application/incoming_invite_link_service.dart';
import 'features/share_good/application/install_referrer_channel.dart';
import 'features/share_good/data/datasources/share_good_local_store.dart';
import 'features/share_good/share_good_config.dart';
import 'features/share_good/application/good_impact_indicator_controller.dart';
import 'features/share_good/application/share_good_notification_controller.dart';

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
  QuranAudioNotificationController? _audioNotificationController;
  AppLinks? _appLinks;
  Future<bool>? _initialRecoveryLink;
  IncomingInviteLinkService? _inviteLinks;
  StreamSubscription<String>? _inviteSubscription;
  String? _lastRoutedInvite;
  bool _launchNavigationReady = false;
  bool _suppressBufferedNavigation = false;
  int _priorityNavigationEpoch = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appInitializedNotifier.addListener(_onInitialized);
    if (!kIsWeb && Platform.isAndroid) {
      final links = _appLinks = AppLinks();
      _initialRecoveryLink = _readInitialRecoveryLink(links);
      _audioNotificationController = QuranAudioNotificationController(
        notificationClicks: AudioService.notificationClicked,
        currentState: () => getIt<QuranContinuousPlayerService>().state,
        canOpenReader: _canOpenAudioReader,
        currentLocation: () =>
            AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        onOpen: (location) => AppRouter.router.go(location),
      )..start();
      _widgetLaunch = HomeWidgetLaunchController(
        events: HomeWidget.widgetClicked,
        initial: HomeWidget.initiallyLaunchedFromHomeWidget,
        onOpen: (uri) => unawaited(_openHomeWidget(uri)),
      )..start();
    }
  }

  bool _canOpenAudioReader() {
    if (!AppInitializer.isInitialized ||
        _suppressBufferedNavigation ||
        _hasPasswordRecovery) {
      return false;
    }
    final path = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    // Kids listening keeps its existing reader context when the app is opened.
    if (path.startsWith(AppRoutes.memorizationPlusKids)) return false;
    return getIt<QuranContinuousPlayerService>().canOpenReaderFromNotification;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appInitializedNotifier.removeListener(_onInitialized);
    unawaited(_widgetLaunch?.dispose());
    unawaited(_audioNotificationController?.dispose());
    unawaited(_inviteSubscription?.cancel());
    unawaited(_inviteLinks?.dispose());
    super.dispose();
  }

  void _onInitialized() {
    if (appInitializedNotifier.value && mounted) {
      _refreshGoodImpact();
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only process lifecycle events after initialization.
    if (!AppInitializer.isInitialized) return;
    getIt<AppUpdateCubit>().setForeground(state == AppLifecycleState.resumed);

    if (state == AppLifecycleState.resumed) {
      _refreshGoodImpact();
      if (getIt.isRegistered<ShareGoodNotificationController>()) {
        unawaited(getIt<ShareGoodNotificationController>().refresh());
      }
      _audioNotificationController?.setReady(_launchNavigationReady);
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
      _audioNotificationController?.setReady(false);
      _saveCurrentLocation();
    }
  }

  void _saveCurrentLocation() {
    if (!AppInitializer.isInitialized) return;
    final uri = AppRouter.router.routerDelegate.currentConfiguration.uri;
    if (AppRouter.isInvitePreviewLocation(uri.path)) return;
    unawaited(getIt<AppSessionService>().saveLocation(uri.toString()));
  }

  void _refreshGoodImpact() {
    if (getIt.isRegistered<GoodImpactIndicatorController>()) {
      unawaited(getIt<GoodImpactIndicatorController>().onResume());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppInitializer.isInitialized) _wireLaunchNavigation();
    // Hold the splash until an enabled Android invite can claim the first
    // route, before Home can redirect to onboarding.
    if (!AppInitializer.isInitialized ||
        (!_launchNavigationReady && _inviteIngressAvailable)) {
      return MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          DigitMaterialLocalizations.delegate,
          ...taliaLocalizationsDelegates,
        ],
        routerConfig: AppRouter.splashOnlyRouter,
      );
    }

    // After initialization, show the full app with all providers.
    return _buildFullApp();
  }

  bool _fullAppWired = false;

  bool get _inviteIngressAvailable =>
      _appLinks != null &&
      getIt.isRegistered<ShareGoodAvailability>() &&
      getIt<ShareGoodAvailability>().isAvailable;

  void _wireLaunchNavigation() {
    if (_fullAppWired) return;
    _fullAppWired = true;
    final notificationService = getIt<TaliaNotificationService>();
    notificationService.onNotificationResponse = _handleNotificationResponse;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_startPostInitializationTasks(notificationService));
      }
    });
  }

  Widget _buildFullApp() {
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
            _priorityNavigationEpoch++;
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
            if (getIt
                .checkLazySingletonInstanceExists<
                  QuranContinuousPlayerService
                >()) {
              getIt<QuranContinuousPlayerService>().refreshMediaMetadata();
            }
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
    final hadPriority = await _applyLaunchNavigation(notificationService);
    if (!mounted) return;
    setState(() => _launchNavigationReady = true);
    _suppressBufferedNavigation = hadPriority;
    _widgetLaunch?.activate();
    _audioNotificationController?.setReady(
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    _suppressBufferedNavigation = false;
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
    if (!mounted ||
        !AppInitializer.isInitialized ||
        _suppressBufferedNavigation ||
        _hasPasswordRecovery) {
      return;
    }
    final epoch = ++_widgetNavigationEpoch;
    final prefs = getIt<SharedPreferences>();
    if (prefs.getBool(LaunchDestination.firstTimePreferenceKey) ?? true) return;
    try {
      final lease = AccountDataBarrier.forPreferences(prefs).capture();
      final profile = await getIt<MemorizationPathResolver>().currentProfile();
      lease.check();
      if (!mounted || epoch != _widgetNavigationEpoch || _hasPasswordRecovery) {
        return;
      }
      final enabled = getIt<ExperienceFlags>().isEnabled(
        ExperienceFeature.homeWidget,
      );
      var target = enabled && profile?.isAdult == true
          ? widgetDeepLinkDestination(uri)
          : AppRoutes.home;
      if (target == widgetWirdMarker) {
        final plan = await getIt<KhatmahRepository>().getActivePlan();
        lease.check();
        if (!mounted ||
            epoch != _widgetNavigationEpoch ||
            _hasPasswordRecovery) {
          return;
        }
        target = widgetWirdReadingRoute(plan, DateTime.now());
      }
      if (uri.path == '/prayer' && target != AppRoutes.home) {
        target = '$target&widgetTap=$epoch';
      }
      AppRouter.router.go(target);
    } on AccountDataUnavailableException {
      // Account transition owns navigation; discard the stale tap.
    } catch (error, stack) {
      // An unreadable profile must not strand the tap: fall back to home.
      TaliaLogger.w('Home widget tap could not resolve profile', error, stack);
      if (mounted && epoch == _widgetNavigationEpoch && !_hasPasswordRecovery) {
        AppRouter.router.go(AppRoutes.home);
      }
    }
  }

  /// The raw response is the single path for Companion and legacy actions.
  Future<void> _handleNotificationResponse(
    NotificationResponseEvent event,
  ) async {
    if (!mounted || !AppInitializer.isInitialized || _hasPasswordRecovery) {
      return;
    }
    final epoch = _priorityNavigationEpoch;
    if (await _claimInviteReminder(event.payload, epoch)) return;
    final outcome = await getIt<PrayerCompanionController>().handle(event);
    if (!mounted || epoch != _priorityNavigationEpoch || _hasPasswordRecovery) {
      return;
    }
    AppRouter.router.go(outcome.route);
  }

  /// Cold start: dependencies are ready here, so the pending launch goes
  /// through the same controller — a companion action is written once during
  /// startup, then the route is applied.
  Future<bool> _applyLaunchNavigation(
    TaliaNotificationService notificationService,
  ) async {
    if (!mounted) return false;
    final pending = notificationService.takePendingLaunch();
    final recoveryLink = await _initialRecoveryLink ?? false;
    if (!mounted) return false;
    final invite = await _startInviteIngress();
    if (!mounted) return false;
    if (_hasPasswordRecovery) {
      AppRouter.router.go(AppRoutes.updatePassword);
      return true;
    }
    // Supabase owns validation of the recovery link and emits the auth state.
    if (recoveryLink || _openInvite(invite)) return true;
    final isFirstTime =
        getIt<SharedPreferences>().getBool(
          LaunchDestination.firstTimePreferenceKey,
        ) ??
        true;
    if (pending == null) {
      if (isFirstTime) AppRouter.router.go(AppRoutes.onboarding);
      return false;
    }
    final event = NotificationResponseEvent(
      payload: pending.payload,
      actionId: pending.actionId,
    );
    if (await _claimInviteReminder(event.payload, _priorityNavigationEpoch)) {
      return true;
    }
    if (isFirstTime) {
      // First-time users always go to onboarding; no notification response
      // (companion or legacy) is applied before onboarding completes.
      AppRouter.router.go(AppRoutes.onboarding);
      return false;
    }
    final outcome = await getIt<PrayerCompanionController>().handle(event);
    if (!mounted) return false;
    if (_hasPasswordRecovery) return true;
    if (outcome.route != AppRoutes.home) {
      AppRouter.router.go(outcome.route);
    }
    return false;
  }

  Future<bool> _claimInviteReminder(String? payload, int epoch) async {
    if (payload == null || !payload.startsWith('sg1|')) return false;
    if (!getIt.isRegistered<ShareGoodNotificationController>()) return true;
    try {
      final lease = AccountDataBarrier.forPreferences(
        getIt<SharedPreferences>(),
      ).capture();
      final session = await getIt<ShareGoodNotificationController>().claim(
        payload,
      );
      lease.check();
      if (session == null ||
          !mounted ||
          epoch != _priorityNavigationEpoch ||
          _hasPasswordRecovery) {
        return true;
      }
      _priorityNavigationEpoch++;
      _widgetNavigationEpoch++;
      AppRouter.router.go(AppRoutes.inviteLocation(session.token));
    } on AccountDataUnavailableException {
      // A profile/account transition owns navigation.
    }
    return true;
  }

  bool get _hasPasswordRecovery {
    if (getIt<AuthCubit>().state is AuthPasswordRecoveryDetected) return true;
    final path = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    return path == AppRoutes.updatePassword ||
        path == AppRoutes.updatePasswordAlias;
  }

  Future<bool> _readInitialRecoveryLink(AppLinks links) async {
    try {
      final raw = await links.getInitialLinkString().timeout(
        const Duration(seconds: 1),
      );
      final uri = raw == null ? null : Uri.tryParse(raw);
      final recovery = Uri.tryParse(SupabaseConfig.passwordRecoveryRedirectTo);
      return uri != null &&
          recovery != null &&
          uri.scheme == recovery.scheme &&
          uri.host == recovery.host &&
          uri.path == recovery.path;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _startInviteIngress() async {
    final links = _appLinks;
    if (links == null || !getIt.isRegistered<ShareGoodAvailability>()) {
      return null;
    }
    final availability = getIt<ShareGoodAvailability>();
    final service = _inviteLinks = IncomingInviteLinkService(
      appLinks: links,
      referrer: const InstallReferrerChannel(),
      store: getIt<ShareGoodLocalStore>(),
      preferences: getIt<SharedPreferences>(),
      links: availability.links,
      isEnabled: () => availability.isAvailable,
    );
    _inviteSubscription = service.tokens.listen((token) {
      if (_launchNavigationReady) _openInvite(token);
    });
    return service.initialToken();
  }

  bool _openInvite(String? token) {
    if (!mounted ||
        !_inviteIngressAvailable ||
        token == null ||
        token == _lastRoutedInvite ||
        _hasPasswordRecovery) {
      return false;
    }
    final route = LaunchDestination.priorityRoute(pendingInvite: token);
    if (route == null) return false;
    _lastRoutedInvite = token;
    _widgetNavigationEpoch++;
    _priorityNavigationEpoch++;
    AppRouter.router.go(route);
    return true;
  }
}
