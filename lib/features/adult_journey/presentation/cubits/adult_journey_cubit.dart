import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../adult_journey_feature_flags.dart';
import '../../application/adult_journey_usecases.dart';
import '../../domain/entities/adult_journey_context.dart';
import '../../domain/entities/adult_journey_preferences.dart';
import '../../domain/entities/adult_journey_suggestion.dart';
import '../../domain/entities/adult_journey_update.dart';
import '../../domain/services/adult_journey_suggestion_policy.dart';
import '../../domain/services/adult_local_date.dart';
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
    required AdultJourneyFlags flags,
    required RecordOwnerProvider owner,
    required Stream<void> accountChanges,
    required DateTime Function() now,
    AdultJourneySuggestionPolicy policy = const AdultJourneySuggestionPolicy(),
  }) : _load = loadAdultJourney,
       _update = updateAdultJourney,
       _flags = flags,
       _owner = owner,
       _now = now,
       _policy = policy,
       _lastOwner = owner.currentOwnerId,
       super(AdultJourneyState.hidden) {
    _accountSub = accountChanges.listen((_) => _onAccountEvent());
  }

  final LoadAdultJourney _load;
  final UpdateAdultJourney _update;
  final AdultJourneyFlags _flags;
  final RecordOwnerProvider _owner;
  final DateTime Function() _now;
  final AdultJourneySuggestionPolicy _policy;
  late final StreamSubscription<void> _accountSub;

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
  ) => _write(SaveAdultProfile(goal: goal, experience: experience));

  Future<bool> snoozeSetup() => _write(SnoozeAdultSetup(_localDate()));

  Future<bool> setTodayMinutes(int minutes) async {
    if (!adultJourneyMinuteChoices.contains(minutes)) return false;
    if (!_flags.isEnabled(AdultJourneyFeature.todayBudget)) return false;
    return _write(SetAdultToday(localDate: _localDate(), minutes: minutes));
  }

  Future<bool> clearToday() => _write(const ClearAdultToday());

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
    // A newer-schema record behaves like no feature at all (spec §5): showing
    // defaults would offer an invite that can never be saved or dismissed.
    if (result.status == AdultJourneyLoadStatus.unavailable ||
        result.status == AdultJourneyLoadStatus.unsupported) {
      return _hide();
    }
    _stateOwner = owner;
    _publish(result.preferences);
  }

  Future<bool> _write(AdultJourneyUpdate command) async {
    final owner = _syncOwner();
    if (!state.isVisible || state.isSaving || _stateOwner != owner) {
      return false;
    }
    final epoch = _epoch;
    final visibility = _visibility;
    _seq++;
    _emit(state.copyWith(isSaving: true, error: null));
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
      if (!isClosed) _syncOwner();
      return false;
    }
    // A load that started while this save was in flight may have read the
    // record before the write: make it stale.
    _seq++;
    // Hidden meanwhile: the record may be saved, but nothing is shown again.
    if (visibility != _visibility || _stateOwner != owner) {
      return result.isSuccess;
    }
    if (!result.isSuccess) {
      _emit(state.copyWith(isSaving: false, error: _errorFor(result.failure)));
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

  void _publish(AdultJourneyPreferences prefs) {
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
      ),
    );
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
    return super.close();
  }
}
