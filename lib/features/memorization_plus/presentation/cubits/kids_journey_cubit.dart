import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/memorization_entities.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

part 'kids_journey_state.dart';

class KidsJourneyCubit extends Cubit<KidsJourneyState> {
  KidsJourneyCubit(this._getJourney, this._getKidsProgress, this._remoteLink)
    : super(const KidsJourneyInitial());

  final GetKidsJourneyUsecase _getJourney;
  final GetKidsProgressUsecase _getKidsProgress;
  final ParentRemoteLinkUsecase _remoteLink;

  Future<void> load({required int surahId}) async {
    emit(const KidsJourneyLoading());
    final journeyResult = await _getJourney(
      GetKidsJourneyParams(surahId: surahId),
    );
    final progressResult = await _getKidsProgress();

    final failure =
        journeyResult.fold((f) => f, (_) => null) ??
        progressResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(KidsJourneyError(failure.message));
      return;
    }

    emit(
      KidsJourneyLoaded(
        surahId: surahId,
        stages: journeyResult.getOrElse(() => const []),
        progress: progressResult.getOrElse(() => const KidsProgress.initial()),
      ),
    );
  }

  Future<void> createRemoteLinkQr() async {
    final current = state;
    if (current is! KidsJourneyLoaded) return;
    emit(current.copyWith(isCreatingLink: true, clearMessage: true));
    final result = await _remoteLink.createChildLinkToken();
    result.fold(
      (failure) => emit(
        current.copyWith(
          isCreatingLink: false,
          message: failure.message,
          clearQrPayload: true,
        ),
      ),
      (token) => emit(
        current.copyWith(
          isCreatingLink: false,
          qrPayload: 'talia-kids-link:$token',
          message: 'تم إنشاء رمز الربط. صالح لمدة 10 دقائق.',
        ),
      ),
    );
  }
}

