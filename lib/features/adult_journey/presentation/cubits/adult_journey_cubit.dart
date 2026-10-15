import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../adult_journey_feature_flags.dart';
import '../../application/adult_journey_launch_resolver.dart';
import '../../application/adult_journey_usecases.dart';
import '../../domain/entities/adult_journey_context.dart';
import '../../domain/entities/adult_journey_preferences.dart';
import '../../domain/entities/adult_journey_suggestion.dart';
import '../../domain/entities/adult_journey_update.dart';
import '../../domain/services/adult_journey_suggestion_policy.dart';
import '../../domain/services/adult_local_date.dart';
import '../../domain/services/adult_return_policy.dart';
import '../adult_journey_safe_routes.dart';
import 'adult_journey_state.dart';

/// Presents the optional adult-journey overlay. Home feeds it through
/// [refreshContext]; Settings only needs [loadPreferences].
///
/// Stale-result guard: [_epoch] changes whenever the account may have changed
/// (barrier event or a different owner id), and [_seq] orders requests. A
/// result is applied only if its epoch is current, the owner is unchanged and
/// (for loads) no newer request or save started, so an A -> B -> A switch
/// never shows A's older result. [_visibility] changes on every hide, so a
/// save that completes after the overlay was hidden (child, unconfirmed
/// adult, flag off) never shows it again.
///
/// Barrier events also fire for ordinary same-owner writes (Khatmah). Those
/// drop in-flight results and re-read instead of hiding; a blocked barrier
/// makes the re-read unavailable, which hides.
class AdultJourneyCubit extends Cubit<AdultJourneyState> {
  AdultJourneyCubit({
    required LoadAdultJourney loadAdultJourney,
    required UpdateAdultJourney updateAdultJourney,
    required this._flags,
    required RecordOwnerProvider owner,
    required Stream<void> accountChanges,
    required this._now,
    this._policy = const AdultJourneySuggestionPolicy(),
    this._launchResolver,
    this._returnPolicy = const AdultReturnPolicy(),
    Stream<String>? preferenceChanges,
  }) : _load = loadAdultJourney,
       _update = updateAdultJourney,
       _owner = owner,
       _lastOwner = owner.currentOwnerId,
       super(AdultJourneyState.hidden) {
    _accountSub = accountChanges.listen((_) => _onAccountEvent());
    _preferencesSub = preferenceChanges?.listen(_onPreferencesChanged);
  }

  final LoadAdultJourney _load;
  final UpdateAdultJourney _update;
  final AdultJourneyFlags _flags;
  final RecordOwnerProvider _owner;
  final DateTime Function() _now;
  final AdultJourneySuggestionPolicy _policy;
  final AdultJourneyLaunchResolver? _launchResolver;
  final AdultReturnPolicy _returnPolicy;
  late final StreamSubscription<void> _accountSub;
  StreamSubscription<String>? _preferencesSub;
  bool _launching = false;

  int _epoch = 0;
  int _seq = 0;
  int _visibility = 0;
  String _lastOwner;
  String? _stateOwner;
  AdultJourneyContext? _context;

  bool get _personalizationOn =>
      _flags.isEnabled(AdultJourneyFeature.personalization);

  /// Settings use: preferences without a Home context (no suggestions). The
  /// caller already gates on the adult path.
  Future<void> loadPreferences() async {
    final owner = _syncOwner();
    _context = null;
    if (!_personalizationOn) return _hide();
    await _reload(owner);
  }

  /// Home use: a new Home load for [context]. Anything but a confirmed adult
  /// of the current owner hides the overlay.
  Future<void> refreshContext(AdultJourneyContext context) async {
    final owner = _syncOwner();
    if (!_personalizationOn || !context.isAdult || context.ownerId != owner) {
      _context = null;
      return _hide();
    }
    _context = context;
    await _reload(owner);
  }

  Future<bool> saveProfile(
    AdultJourneyGoal goal,
    AdultJourneyExperience? experience,
  ) => _write(
    SaveAdultProfile(goal: goal, experience: experience),
    AdultJourneyErrorSource.profile,
  );

  Future<bool> snoozeSetup() =>
      _write(SnoozeAdultSetup(_localDate()), AdultJourneyErrorSource.snooze);

  Future<bool> setTodayMinutes(int minutes) async {
    if (!adultJourneyMinuteChoices.contains(minutes)) return false;
    if (!_flags.isEnabled(AdultJourneyFeature.todayBudget)) return false;
    return _write(
      SetAdultToday(localDate: _localDate(), minutes: minutes),
      AdultJourneyErrorSource.today,
    );
  }

  Future<bool> clearToday() =>
      _write(const ClearAdultToday(), AdultJourneyErrorSource.today);

  bool get _gentleReturnOn =>
      _flags.isEnabled(AdultJourneyFeature.gentleReturn);

  /// Records an eligible adult Home visit (spec §4.3). The caller has checked
  /// that Home is in the foreground; this checks the flag, a loaded confirmed
  /// adult on Home, and the owner. Silent: a failure shows nothing, and the
  /// repository writes at most once per local day.
  Future<void> recordHomeVisit() async {
    if (!_gentleReturnOn) return;
    final owner = _syncOwner();
    if (!state.isVisible || _stateOwner != owner || _context == null) return;
    final epoch = _epoch;
    final visibility = _visibility;
    AdultJourneySaveResult result;
    try {
      result = await _update(owner, RecordAdultHomeVisit(_now().toUtc()));
    } catch (error, stack) {
      TaliaLogger.w('Adult journey visit not recorded', error, stack);
      return;
    }
    if (!_isCurrent(owner, epoch)) {
      if (!isClosed) _syncOwner();
      return;
    }
    if (visibility != _visibility || _stateOwner != owner) return;
    if (!result.isSuccess || !result.changed || state.isSaving) return;
    _seq++;
    _publish(result.preferences!);
  }

  /// «بداية خفيفة اليوم»: five minutes preferring existing review. Never
  /// opens a session by itself.
  Future<bool> startLightReturn() {
    if (!_flags.gentleReturnTimeActionsEnabled) return Future.value(false);
    return _write(
      StartAdultLightReturn(_localDate()),
      AdultJourneyErrorSource.returnAction,
    );
  }

  /// «اختر وقتي»: the invitation is done for today; the time card shows its
  /// choices, and nothing is saved until a time is picked.
  Future<bool> chooseReturnTime() {
    if (!_flags.gentleReturnTimeActionsEnabled) return Future.value(false);
    return _write(
      DismissAdultReturn(_localDate()),
      AdultJourneyErrorSource.returnAction,
    );
  }

  /// «أكمل كالمعتاد»: clears today's choice and the invitation; the profile,
  /// plans and review dates are untouched.
  Future<bool> continueAsUsual() => _write(
    ContinueAdultAsUsual(_localDate()),
    AdultJourneyErrorSource.returnAction,
  );

  /// The route to open for [suggestion], resolved now (Phase B). Null means
  /// "do not navigate": hidden overlay, another launch in progress, an
  /// account change during the lookup, or a child profile. Without a
  /// resolver (tests) the Phase A safe route is used.
  Future<String?> resolveLaunch(AdultJourneySuggestion suggestion) async {
    final owner = _syncOwner();
    if (!state.isVisible || _stateOwner != owner || _launching) return null;
    final resolver = _launchResolver;
    if (resolver == null) return adultJourneySafeRoute(suggestion);
    final epoch = _epoch;
    final visibility = _visibility;
    _launching = true;
    String? route;
    try {
      route = await resolver.resolve(
        suggestion: suggestion,
        expectedOwnerId: owner,
      );
    } catch (error, stack) {
      TaliaLogger.w('Adult journey launch failed', error, stack);
    } finally {
      _launching = false;
    }
    if (!_isCurrent(owner, epoch) || visibility != _visibility) return null;
    return route;
  }

  Future<void> _reload(String owner) async {
    final epoch = _epoch;
    final seq = ++_seq;
    AdultJourneyLoadResult result;
    try {
      result = await _load(owner);
    } catch (error, stack) {
      TaliaLogger.w('Adult journey load failed', error, stack);
      result = AdultJourneyLoadResult.unavailable;
    }
    if (!_isCurrent(owner, epoch) || seq != _seq) {
      if (!isClosed) _syncOwner();
      return;
    }
    _lastLoadStatus = result.status;
    // A newer-schema record behaves like no feature at all (spec §5): showing
    // defaults would offer an invite that can never be saved or dismissed.
    if (result.status == AdultJourneyLoadStatus.unavailable ||
        result.status == AdultJourneyLoadStatus.unsupported) {
      return _hide();
    }
    // A re-read keeps a pending error visible; only a new action clears it.
    final keepError = _stateOwner == owner && state.isVisible;
    _stateOwner = owner;
    _publish(result.preferences, keepError: keepError);
  }

  Future<bool> _write(
    AdultJourneyUpdate command,
    AdultJourneyErrorSource source,
  ) async {
    final owner = _syncOwner();
    if (!state.isVisible || state.isSaving || _stateOwner != owner) {
      return false;
    }
    final epoch = _epoch;
    final visibility = _visibility;
    _seq++;
    _emit(state.copyWith(isSaving: true, error: null, errorSource: null));
    AdultJourneySaveResult result;
    try {
      result = await _update(owner, command);
    } catch (error, stack) {
      TaliaLogger.w('Adult journey save failed', error, stack);
      result = const AdultJourneySaveResult.failed(
        AdultJourneySaveFailure.storage,
      );
    }
    if (!_isCurrent(owner, epoch)) {
      if (isClosed) return false;
      final sameOwner = owner == _owner.currentOwnerId;
      _syncOwner();
      // A same-owner barrier event (e.g. a Khatmah write) only re-reads: the
      // record was saved and that re-read publishes it. A blocked barrier made
      // the save itself fail. Another owner always counts as failure.
      return sameOwner && result.isSuccess;
    }
    // A load that started while this save was in flight may have read the
    // record before the write: make it stale.
    _seq++;
    // Hidden meanwhile: the record may be saved, but nothing is shown again.
    if (visibility != _visibility || _stateOwner != owner) {
      return result.isSuccess;
    }
    if (!result.isSuccess) {
      _emit(
        state.copyWith(
          isSaving: false,
          error: _errorFor(result.failure),
          errorSource: source,
        ),
      );
      return false;
    }
    _publish(result.preferences ?? state.preferences);
    return true;
  }

  AdultJourneyErrorCode _errorFor(AdultJourneySaveFailure? failure) {
    return switch (failure) {
      AdultJourneySaveFailure.unavailable => AdultJourneyErrorCode.unavailable,
      AdultJourneySaveFailure.unsupportedRecord =>
        AdultJourneyErrorCode.unsupportedRecord,
      _ => AdultJourneyErrorCode.saveFailed,
    };
  }

  void _publish(AdultJourneyPreferences prefs, {bool keepError = false}) {
    final now = _now();
    final localDate = AdultLocalDate.format(now.toLocal());
    final budgetOn = _flags.isEnabled(AdultJourneyFeature.todayBudget);
    final context = _context;
    final suggestions = budgetOn && context != null
        ? _policy.select(
            context: AdultJourneyContext(
              ownerId: context.ownerId,
              isAdult: context.isAdult,
              now: now,
              actions: context.actions,
              hasActiveAdultPlan: context.hasActiveAdultPlan,
              hasAdultReviewRecords: context.hasAdultReviewRecords,
              hasDueAdultReview: context.hasDueAdultReview,
            ),
            preferences: prefs,
          )
        : const <AdultJourneySuggestion>[];
    _emit(
      AdultJourneyState(
        status: AdultJourneyStatus.ready,
        preferences: prefs,
        suggestions: suggestions,
        localDate: localDate,
        todayBudgetEnabled: budgetOn,
        setupInviteDue:
            !prefs.profileCompleted && !prefs.isSetupSnoozedOn(localDate),
        returnOffer: _returnOfferFor(prefs, now, onHome: context != null),
        returnTimeActionsEnabled: _flags.gentleReturnTimeActionsEnabled,
        error: keepError ? state.error : null,
        errorSource: keepError ? state.errorSource : null,
      ),
    );
  }

  /// Home only. A self-described «عائد» sees the options until the first
  /// dismissal or choice, without any absence claim; afterwards only a real
  /// seven-day gap brings the invitation back.
  AdultReturnDecision? _returnOfferFor(
    AdultJourneyPreferences prefs,
    DateTime now, {
    required bool onHome,
  }) {
    if (!onHome || !_gentleReturnOn) return null;
    final decision = _returnPolicy.evaluate(
      now: now,
      lastHomeSeenAtUtc: prefs.lastHomeSeenAtUtc,
      returnOfferLocalDate: prefs.returnOfferLocalDate,
      returnDismissedLocalDate: prefs.returnDismissedLocalDate,
      explicitlyReturning:
          prefs.experience == AdultJourneyExperience.returning &&
          prefs.returnDismissedLocalDate == null,
    );
    return decision.showOffer ? decision : null;
  }

  String _localDate() => AdultLocalDate.format(_now().toLocal());

  /// Detects an owner change even when no barrier event was seen.
  String _syncOwner() {
    final owner = _owner.currentOwnerId;
    if (owner != _lastOwner) _syncOwnerOn(owner);
    return owner;
  }

  bool _isCurrent(String owner, int epoch) =>
      !isClosed && epoch == _epoch && owner == _owner.currentOwnerId;

  void _invalidate() {
    _epoch++;
    _seq++;
    _context = null;
    _hide();
  }

  /// Another screen (Settings, or a visit) saved this owner's record: re-read
  /// so Home and Settings agree. Own saves are skipped while [isSaving]; they
  /// publish their result themselves.
  void _onPreferencesChanged(String ownerId) {
    if (ownerId != _owner.currentOwnerId || _stateOwner != ownerId) return;
    if (!state.isVisible || state.isSaving) return;
    unawaited(_reload(ownerId));
  }

  /// Re-publishes for a new local day (Home left open past midnight) so
  /// yesterday's time choice and suggestions are not shown.
  void refreshDay() {
    final owner = _syncOwner();
    // Never mid-save: publishing would re-enable the buttons early.
    if (!state.isVisible || state.isSaving || _stateOwner != owner) return;
    if (state.localDate == _localDate()) return;
    _publish(state.preferences, keepError: false);
  }

  /// Why the last read hid the overlay (Settings picks its message from it).
  AdultJourneyLoadStatus? get lastLoadStatus => _lastLoadStatus;
  AdultJourneyLoadStatus? _lastLoadStatus;

  void _onAccountEvent() {
    final owner = _owner.currentOwnerId;
    if (owner != _lastOwner) return _syncOwnerOn(owner);
    _epoch++;
    _seq++;
    final stateOwner = _stateOwner;
    if (!state.isVisible || stateOwner != owner) return;
    unawaited(_reload(owner));
  }

  void _syncOwnerOn(String owner) {
    _lastOwner = owner;
    _invalidate();
  }

  void _hide() {
    _stateOwner = null;
    _seq++;
    _visibility++;
    _emit(AdultJourneyState.hidden);
  }

  void _emit(AdultJourneyState next) {
    if (!isClosed) emit(next);
  }

  @override
  Future<void> close() async {
    await _accountSub.cancel();
    await _preferencesSub?.cancel();
    return super.close();
  }
}
