import 'quran_reciter.dart';

enum DownloadPhase {
  checking,
  waitingForNetworkConfirmation,
  insufficientSpace,
  downloading,
  completed,
  cancelled,
  failed,
}

enum DownloadError { metadata, download }

class DownloadProgress {
  const DownloadProgress({
    required this.phase,
    required this.completedAyahs,
    required this.totalAyahs,
    this.reciter,
    this.surahId,
    this.error,
    this.spaceUnknown = false,
  });
  final DownloadPhase phase;
  final int completedAyahs;
  final int totalAyahs;
  final QuranReciter? reciter;
  final int? surahId;
  final DownloadError? error;
  final bool spaceUnknown;
}
