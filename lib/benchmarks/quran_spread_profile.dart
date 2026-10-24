import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/services/get_page.dart';

import '../features/quran/domain/services/quran_spread_policy.dart';
import '../features/quran/presentation/widgets/app_quran_page_content.dart';
import '../features/quran/presentation/widgets/app_quran_page_view.dart';
import '../features/quran/presentation/widgets/mushaf_page_flip_physics.dart';
import '../features/quran/presentation/widgets/quran_spread_view.dart';
import 'quran_profile_recorder.dart';

/// Alternate entry point: never reached by the production router.
void main() {
  if (!kProfileMode) throw StateError('QCF measurement requires profile mode.');
  if (const String.fromEnvironment('QURAN_PROFILE_RUN_ID').isEmpty) {
    throw StateError('QURAN_PROFILE_RUN_ID must identify this run.');
  }
  final config = QuranProfileConfig.parse(
    const String.fromEnvironment('QURAN_PROFILE_MODE'),
  );
  runApp(
    MaterialApp(
      home: QuranSpreadProfile(
        config: config,
        automate: const bool.fromEnvironment(
          'QURAN_PROFILE_AUTOMATE',
          defaultValue: true,
        ),
      ),
    ),
  );
}

class QuranSpreadProfile extends StatefulWidget {
  const QuranSpreadProfile({
    super.key,
    required this.config,
    this.automate = true,
  });
  final QuranProfileConfig config;
  final bool automate;

  @override
  State<QuranSpreadProfile> createState() => _QuranSpreadProfileState();
}

class _QuranSpreadProfileState extends State<QuranSpreadProfile> {
  final _controller = PageController();
  final _offset = ValueNotifier<double>(0);
  final _recorder = QuranProfileRecorder();
  final _turns = <Map<String, Object?>>[];
  final _zoomed = <int>{};
  late final List<qcf.QuranPage> _pages;
  late final List<qcf.HighlightVerse> _highlights;
  late final Widget Function(BuildContext, int) _basmallah;
  bool _fontsReady = true;
  int _completedTurns = 0;

  @override
  void initState() {
    super.initState();
    final loader = GetPage()..getQuran(604);
    _pages = loader.staticPages;
    _highlights = [
      for (final page in _pages)
        qcf.HighlightVerse(
          verseNumber: page.ayahs.first.ayahNumber,
          surah: page.ayahs.first.surahNumber,
          page: page.pageNumber,
          color: const Color(0x334CAF50),
        ),
    ];
    _basmallah = structuralBasmallahBuilder(null);
    _controller.addListener(_trackOffset);
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    if (widget.automate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
    }
  }

  void _trackOffset() => _offset.value = _controller.page ?? 0;

  List<int> _visible(int index) {
    if (!widget.config.spread) return [index + 1];
    final spread = spreadAt(index);
    return [spread.rightPage, spread.leftPage].whereType<int>().toList();
  }

  void _prefetch(int index) {
    for (final page in _visible(index)) {
      unawaited(
        qcf.QcfFontLoader.preloadPages(page, radius: 8).catchError((
          Object error,
        ) {
          _fontsReady = false;
        }),
      );
    }
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _recorder.add(
        QuranFrameSample(
          timing.timestampInMicroseconds(FramePhase.vsyncStart),
          timing.buildDuration.inMicroseconds,
          timing.rasterDuration.inMicroseconds,
          timing.totalSpan.inMicroseconds,
        ),
      );
    }
  }

  Future<void> _run() async {
    try {
      _prefetch(0);
      await Future.wait(
        _visible(0).map(qcf.QcfFontLoader.ensureFontLoaded),
      ).timeout(const Duration(seconds: 20));
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final start = await quranProfileFrameBoundary();
      for (var turn = 1; turn <= widget.config.turns && mounted; turn++) {
        await _turn(turn);
      }
      if (!mounted) return;
      final end = await quranProfileFrameBoundary();
      // Timings arrive in batches; include late batches by their frame timestamp.
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) await _emit(start, end);
    } catch (error) {
      debugPrint('QURAN_PROFILE_ERROR ${jsonEncode({'error': '$error'})}');
    }
  }

  Future<void> _turn(int index) async {
    final startUs = await quranProfileFrameBoundary();
    await _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.linear,
    );
    if (!mounted) return;
    _prefetch(index);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final visible = _visible(index);
    final ready = visible.every(qcf.QcfFontLoader.isFontLoaded);
    final endUs = await quranProfileFrameBoundary();
    if (!mounted) return;
    _fontsReady = _fontsReady && ready;
    _completedTurns++;
    _turns.add({
      'turn': index,
      'startUs': startUs,
      'endUs': endUs,
      'canonicalPages': visible,
      'prefetchCenters': visible,
      'fontsReady': ready,
      'rssBytes': ProcessInfo.currentRss,
      'peakRssBytes': ProcessInfo.maxRss,
    });
  }

  Future<void> _emit(int start, int end) async {
    final viewport = MediaQuery.sizeOf(context);
    final peakRss = ProcessInfo.maxRss;
    final report = _recorder.report(startUs: start, endUs: end);
    final mode = widget.config.spread ? 'spread' : 'single';
    final evidence = {
      'mode': mode,
      'logicalWidth': viewport.width,
      'runId': const String.fromEnvironment('QURAN_PROFILE_RUN_ID'),
      'revision': const String.fromEnvironment(
        'QURAN_PROFILE_REVISION',
        defaultValue: 'unrecorded',
      ),
      'qcfVersion': '0.0.8',
      'dartVersion': Platform.version,
      'os': Platform.operatingSystemVersion,
      'highlightFixture':
          'first canonical ayah of every page, same list in both modes',
      'prefetchRadius': 8,
      'tajweed': true,
      'theme': 'light',
      'logicalHeight': viewport.height,
      'dpr': MediaQuery.devicePixelRatioOf(context),
      'targetViewport': viewport == const Size(1280, 800),
      'completedTurns': _completedTurns,
      'fontsReady': _fontsReady,
      'visualValidation': 'pending',
      'performanceVerdict': 'pending',
      'peakRssBytes': peakRss,
      'turns': _turns,
      ...report,
    };
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/quran_profile_${mode}_'
      '${DateTime.now().toUtc().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonEncode(evidence), flush: true);
    // Raw frames go to a file: Android can truncate a large single log line.
    debugPrint('QURAN_PROFILE_FILE ${file.path}');
    // Devices without run-as cannot read the file; log the aggregates too.
    final summary = Map<String, Object?>.of(evidence)
      ..removeWhere((_, value) => value is List);
    debugPrint('QURAN_PROFILE_SUMMARY ${jsonEncode(summary)}');
  }

  Widget _page(int page) => QuranPagePaneViewport(
    child: AppQuranPageContent(
      key: ValueKey('profile_page_$page'),
      page: _pages[page - 1],
      pageController: _controller,
      highlights: _highlights,
      isDarkMode: false,
      basmallahBuilder: _basmallah,
      onZoomChanged: (zoomed) {
        if (!mounted) return;
        setState(() {
          zoomed ? _zoomed.add(page) : _zoomed.remove(page);
        });
      },
    ),
  );

  Widget _spreadPager() => Directionality(
    textDirection: TextDirection.rtl,
    child: MushafPageCurlOverlay(
      pageOffsetNotifier: _offset,
      child: PageView.builder(
        controller: _controller,
        itemCount: spreadCount(),
        allowImplicitScrolling: true,
        physics: _zoomed.isNotEmpty
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
        itemBuilder: (context, index) =>
            QuranSpreadView(spread: spreadAt(index), pageBuilder: _page),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: widget.config.spread
        ? _spreadPager()
        : AppQuranPageView(
            pageController: _controller,
            highlights: _highlights,
            isDarkMode: false,
          ),
  );

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _controller.removeListener(_trackOffset);
    _controller.dispose();
    _offset.dispose();
    super.dispose();
  }
}

Future<int> quranProfileFrameBoundary() async {
  SchedulerBinding.instance.scheduleFrame();
  await SchedulerBinding.instance.endOfFrame;
  return SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
}
