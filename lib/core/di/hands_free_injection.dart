import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/surah_names.dart';
import '../experience/experience_feature_flags.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../memorization/memorization_path_resolver.dart';
import '../privacy/recitation_voice_consent.dart';
import '../services/audio_cache_service.dart';
import '../services/quran_continuous_player_service.dart';
import '../services/quran_reciter_service.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../features/memorization_plus/data/listening/listening_recitation_capture.dart';
import '../../features/memorization_plus/data/hands_free/hands_free_review_source.dart';
import '../../features/memorization_plus/data/hands_free/hands_free_practice_audio.dart';
import '../../features/memorization_plus/data/hands_free/hands_free_audio_session.dart';
import '../../features/memorization_plus/data/hands_free/hands_free_warning_store.dart';
import '../../features/memorization_plus/presentation/cubits/hands_free_review_cubit.dart';

/// Factory only: media service and hardware are not resolved during startup.
void registerHandsFreeReview(GetIt getIt) {
  getIt.registerFactory<HandsFreeReviewCubit>(() {
    final barrier = AccountDataBarrier.forPreferences(
      getIt<SharedPreferences>(),
    );
    final path = getIt<MemorizationPathResolver>();
    final source = HandsFreeReviewSource(
      getIt<MemorizationPlusRepository>(),
      getIt<QuranRepository>(),
      getIt<RecordOwnerProvider>(),
      barrier,
      path,
    );
    final warning = HandsFreeWarningStore(
      getIt<SharedPreferences>(),
      getIt<RecordOwnerProvider>(),
      barrier,
    );
    return HandsFreeReviewCubit(
      load: source.load,
      warningAccepted: () => warning.hasAccepted,
      saveWarning: warning.accept,
      audio: JustAudioHandsFreePractice(
        getIt<AudioCacheService>(),
        getIt<QuranReciterService>().currentReciter.value,
      ),
      capture: SpeechToTextListeningCapture(
        voiceConsent: getIt<RecitationVoiceConsent>().ensure,
      ),
      session: PlatformHandsFreeAudioSession(),
      cancelMediaAcquisition: (delegate) =>
          getIt<QuranContinuousPlayerService>().cancelHandsFreeAcquisition(
            delegate,
          ),
      acquireMedia: (delegate) =>
          getIt<QuranContinuousPlayerService>().acquireHandsFreeMedia(delegate),
      mediaTitle: (ref) => SurahNames.nameAr(ref.surahId),
      isEnabled: () =>
          getIt<ExperienceFlags>().isEnabled(ExperienceFeature.handsFreeReview),
      authorityChanges: [barrier.changes, path.changes],
      // Streams also fire for unrelated writes; only a real owner, lease
      // generation or adult-path difference ends the round.
      authoritySnapshot: () async {
        final profile = await path.currentProfile();
        return '${getIt<RecordOwnerProvider>().currentOwnerId}|'
            '${barrier.generation}|${profile?.isAdult == true}';
      },
    );
  });
}
