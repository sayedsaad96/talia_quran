import 'package:flutter/foundation.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/services/get_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/app_session_service.dart';
import '../../../../core/utils/talia_logger.dart';
import '../datasources/quran_local_datasource.dart';

/// Warms up the Quran rendering pipeline in the background after launch so
/// any surah/page opens instantly, without the shimmer skeleton.
///
/// Mushaf pages are drawn with a dedicated QCF font per page (604 fonts).
/// Font registration in the Flutter engine is session-scoped, so every
/// launch must re-register each page's font before that page can render.
/// [warmUp]:
/// 1. Registers fonts for the pages the user is most likely to open first
///    (last-read location ± surrounding pages, Al-Fatihah, Al-Baqarah).
/// 2. Parses the page layout data and quran.json once, so the reader cubits
///    find everything cached when the reader opens.
/// 3. Registers all remaining fonts via [qcf.QcfFontLoader.setupFontsAtStartup].
///    The first launch also extracts every font to disk; later launches only
///    re-read the extracted files (batched).
class QuranWarmupService {
  QuranWarmupService({
    required QuranLocalDatasource datasource,
    required AppSessionService sessionService,
    required SharedPreferences prefs,
  }) : _datasource = datasource,
       _sessionService = sessionService,
       _prefs = prefs;

  static const _warmedFlagKey = 'quran_fonts_warmed_v1';

  /// Lets the home screen render its first frames before warm-up work starts.
  static const _initialDelay = Duration(seconds: 2);

  static const _priorityRadius = 3;

  final QuranLocalDatasource _datasource;
  final AppSessionService _sessionService;
  final SharedPreferences _prefs;

  bool _started = false;

  /// Runs the full warm-up once per session. Safe to call repeatedly.
  Future<void> warmUp() {
    if (_started) return Future.value();
    _started = true;
    return _runWarmup();
  }

  Future<void> _runWarmup() async {
    await Future<void>.delayed(_initialDelay);

    try {
      await _loadPriorityFonts();
    } catch (error, stack) {
      TaliaLogger.e('Quran warm-up: priority fonts failed', error, stack);
    }

    try {
      GetPage().getQuran(qcf.QcfFontLoader.totalPages);
      await _datasource.ensureLoaded();
    } catch (error, stack) {
      TaliaLogger.e('Quran warm-up: data warm-up failed', error, stack);
    }

    try {
      await qcf.QcfFontLoader.setupFontsAtStartup(
        onProgress: (progress) {
          if (progress >= 1.0) {
            TaliaLogger.d('QURAN WARMUP: all fonts registered');
          }
        },
      );
      await _prefs.setBool(_warmedFlagKey, true);
    } catch (error, stack) {
      TaliaLogger.e('Quran warm-up: font registration failed', error, stack);
      // Allow a retry within the same session if something re-triggers us.
      _started = false;
    }
  }

  Future<void> _loadPriorityFonts() async {
    for (final page in buildPriorityPages(
      _sessionService.getLastRestorableLocation(),
    )) {
      await qcf.QcfFontLoader.ensureFontLoaded(page);
    }
  }

  /// Pages that must render without any skeleton even while the full warm-up
  /// is still running: the opening of the mushaf plus the window around the
  /// user's last-read page.
  @visibleForTesting
  static List<int> buildPriorityPages(String? lastLocation) {
    final pages = <int>{1, 2};
    final center = parsePageFromLocation(lastLocation);
    if (center != null) {
      for (
        var page = center - _priorityRadius;
        page <= center + _priorityRadius;
        page++
      ) {
        if (page >= 1 && page <= qcf.QcfFontLoader.totalPages) {
          pages.add(page);
        }
      }
    }
    return pages.toList()..sort();
  }

  /// Extracts a mushaf page number (1-604) from a restorable location such as
  /// `/quran/page/42` or `/quran/surah/2`, or `null` when the location does
  /// not point at a specific Quran page.
  @visibleForTesting
  static int? parsePageFromLocation(String? location) {
    if (location == null) return null;
    final uri = Uri.tryParse(location);
    if (uri == null || uri.pathSegments.length != 3) return null;
    final segments = uri.pathSegments;
    if (segments[0] != 'quran') return null;

    if (segments[1] == 'page') {
      final page = int.tryParse(segments[2]);
      if (page == null || page < 1 || page > qcf.QcfFontLoader.totalPages) {
        return null;
      }
      return page;
    }

    if (segments[1] == 'surah') {
      final surahId = int.tryParse(segments[2]);
      if (surahId == null || surahId < 1 || surahId > qcf.totalSurahCount) {
        return null;
      }
      return qcf.getPageNumber(surahId, 1);
    }

    return null;
  }
}
