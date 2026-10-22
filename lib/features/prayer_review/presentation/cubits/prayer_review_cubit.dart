import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/memorization/v2/self_grade.dart';
import '../../../../core/prayer_review/manual_prayer_review_committer.dart';
import '../../../../core/prayer_review/prayer_review_offer_service.dart';
import '../../../prayer_companion/domain/entities/prayer_companion.dart';
import '../../domain/entities/prayer_review_authority.dart';
import '../../domain/entities/prayer_review_selection.dart';
import '../../../quran/domain/entities/quran_entities.dart';

enum PrayerReviewStatus {
  initial,
  loading,
  unavailable,
  ready,
  saving,
  saved,
  loadFailed,
  saveFailed,
}

final class PrayerReviewState {
  PrayerReviewState({
    required this.status,
    this.offer,
    List<Ayah> ayahs = const [],
  }) : ayahs = List.unmodifiable(ayahs);
  final PrayerReviewStatus status;
  final PrayerReviewOffer? offer;
  final List<Ayah> ayahs;
}

typedef PrayerReviewOfferLoader =
    Future<PrayerReviewOffer?> Function(
      PrayerOccurrence occurrence, {
      bool allowSelection,
    });

final class PrayerReviewCubit extends Cubit<PrayerReviewState> {
  PrayerReviewCubit({
    required this._captureAuthority,
    required Stream<void> accountChanges,
    required this._loadOffer,
    required this._readPassage,
    required this._saveGrade,
  }) : super(PrayerReviewState(status: PrayerReviewStatus.initial)) {
    _subscription = accountChanges.listen((_) => _onAccountChanged());
  }

  final PrayerReviewAuthority Function() _captureAuthority;
  final PrayerReviewOfferLoader _loadOffer;
  final Future<List<Ayah>> Function(PrayerReviewSelection) _readPassage;
  final Future<ManualPrayerReviewResult> Function(
    PrayerReviewOffer,
    V2SelfGrade,
  )
  _saveGrade;
  late final StreamSubscription<void> _subscription;
  PrayerReviewAuthority? _authority;
  int _request = 0;
  bool _closing = false;

  Future<void> load(
    PrayerOccurrence occurrence, {
    bool allowSelection = true,
  }) async {
    if (_closing || isClosed || state.status == PrayerReviewStatus.saving) {
      return;
    }
    final request = ++_request;
    emit(PrayerReviewState(status: PrayerReviewStatus.loading));
    try {
      _authority = _captureAuthority();
      final offer = await _loadOffer(
        occurrence,
        allowSelection: allowSelection,
      );
      if (!_current(request)) return;
      if (offer == null) {
        emit(PrayerReviewState(status: PrayerReviewStatus.unavailable));
        return;
      }
      offer.authority.check();
      if (offer.selection.ownerId != _authority!.ownerId) {
        throw const AccountDataUnavailableException();
      }
      final ayahs = await _readPassage(offer.selection);
      if (!_current(request)) return;
      offer.authority.check();
      _validatePassage(offer.selection, ayahs);
      emit(
        PrayerReviewState(
          status: PrayerReviewStatus.ready,
          offer: offer,
          ayahs: ayahs,
        ),
      );
    } on AccountDataUnavailableException {
      if (_current(request)) _expire();
    } catch (_) {
      if (_current(request)) {
        emit(PrayerReviewState(status: PrayerReviewStatus.loadFailed));
      }
    }
  }

  Future<void> grade(V2SelfGrade grade) async {
    if (_closing ||
        isClosed ||
        !{
          PrayerReviewStatus.ready,
          PrayerReviewStatus.saveFailed,
        }.contains(state.status)) {
      return;
    }
    final offer = state.offer;
    if (offer == null) return;
    final request = _request;
    final ayahs = state.ayahs;
    try {
      offer.authority.check();
      emit(
        PrayerReviewState(
          status: PrayerReviewStatus.saving,
          offer: offer,
          ayahs: ayahs,
        ),
      );
      await _saveGrade(offer, grade);
      if (!_current(request)) return;
      offer.authority.check();
      emit(PrayerReviewState(status: PrayerReviewStatus.saved));
    } on AccountDataUnavailableException {
      if (_current(request)) _expire();
    } catch (_) {
      if (_current(request)) {
        emit(
          PrayerReviewState(
            status: PrayerReviewStatus.saveFailed,
            offer: offer,
            ayahs: ayahs,
          ),
        );
      }
    }
  }

  void _validatePassage(PrayerReviewSelection selected, List<Ayah> ayahs) {
    if (ayahs.length != selected.endAyah - selected.startAyah + 1) {
      throw const FormatException('Incomplete prayer review passage');
    }
    for (var i = 0; i < ayahs.length; i++) {
      if (ayahs[i].surahId != selected.surahId ||
          ayahs[i].numberInSurah != selected.startAyah + i ||
          ayahs[i].text.isEmpty) {
        throw const FormatException('Invalid prayer review passage');
      }
    }
  }

  bool _current(int request) {
    if (_closing || isClosed || request != _request) return false;
    try {
      _authority?.check();
      return true;
    } on AccountDataUnavailableException {
      _expire();
      return false;
    }
  }

  void _onAccountChanged() {
    try {
      _authority?.check();
    } on AccountDataUnavailableException {
      _expire();
    }
  }

  void _expire() {
    _request++;
    _authority = null;
    if (!_closing && !isClosed) {
      emit(PrayerReviewState(status: PrayerReviewStatus.unavailable));
    }
  }

  @override
  Future<void> close() async {
    if (_closing || isClosed) return;
    _expire();
    _closing = true;
    await _subscription.cancel();
    return super.close();
  }
}
