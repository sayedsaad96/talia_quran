import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/services/kids_adventure_regions.dart';

/// The kids certificates earned so far (synchronous local read).
typedef KidsCertificatesLoader = List<CertificateAward> Function();

sealed class KidsTreasuresState extends Equatable {
  const KidsTreasuresState();

  @override
  List<Object?> get props => const [];
}

final class KidsTreasuresLoading extends KidsTreasuresState {
  const KidsTreasuresLoading();
}

final class KidsTreasuresLoaded extends KidsTreasuresState {
  const KidsTreasuresLoaded(this.regions, this.certificates);

  final List<KidsRegionProgress> regions;
  final List<CertificateAward> certificates;

  @override
  List<Object?> get props => [regions, certificates];
}

final class KidsTreasuresError extends KidsTreasuresState {
  const KidsTreasuresError(this.message);

  /// A cubit message code, resolved in the UI.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Region progress and earned certificates for the kids «كنوزي» page.
class KidsTreasuresCubit extends Cubit<KidsTreasuresState> {
  KidsTreasuresCubit(
    this._memorizationRepository,
    this._quranRepository, {
    required KidsCertificatesLoader certificatesLoader,
  }) : _certificatesLoader = certificatesLoader,
       super(const KidsTreasuresLoading());

  final MemorizationPlusRepository _memorizationRepository;
  final QuranRepository _quranRepository;
  final KidsCertificatesLoader _certificatesLoader;

  Future<void> load() async {
    emit(const KidsTreasuresLoading());
    try {
      final logsResult = await _memorizationRepository.getKidsSessionLogs();
      final surahsResult = await _quranRepository.getSurahs();
      final failure =
          logsResult.fold<String?>((f) => f.message, (_) => null) ??
          surahsResult.fold<String?>((f) => f.message, (_) => null);
      if (failure != null) {
        if (!isClosed) emit(KidsTreasuresError(failure));
        return;
      }
      final logs = logsResult.getOrElse(() => const []);
      final surahs = surahsResult.getOrElse(() => const []);
      final memorized = kidsMemorizedSurahIds(logs, {
        for (final surah in surahs) surah.id: surah.ayahCount,
      });
      final certificates = _certificatesLoader();
      if (isClosed) return;
      emit(KidsTreasuresLoaded(kidsRegionProgress(memorized), certificates));
    } catch (_) {
      if (!isClosed) {
        emit(const KidsTreasuresError(CubitMessageCodes.errorUnknown));
      }
    }
  }
}
