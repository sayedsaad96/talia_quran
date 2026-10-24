import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/benchmarks/quran_profile_recorder.dart';

void main() {
  test('validates mode and exactly thirty available turns', () {
    expect(QuranProfileConfig.parse('single').turns, 30);
    expect(QuranProfileConfig.parse('spread').spread, isTrue);
    expect(() => QuranProfileConfig.parse('invalid'), throwsArgumentError);
  });

  test('filters by frame timestamps rather than callback arrival', () {
    final recorder = QuranProfileRecorder();
    recorder.add(const QuranFrameSample(10, 100, 200, 300));
    recorder.add(const QuranFrameSample(20, 200, 300, 400));
    recorder.add(const QuranFrameSample(20, 999, 999, 999));
    recorder.add(const QuranFrameSample(30, 300, 400, 500));
    final report = recorder.report(startUs: 20, endUs: 30);
    expect(report['sampleCount'], 1);
    expect(report['meanTotalUs'], 400);
    expect(report['maxTotalUs'], 400);
    expect(report['p95TotalUs'], 400);
    expect(report['meanBuildUs'], 200);
    expect(report['maxRasterUs'], 300);
    expect(report['over16ms'], 0);
  });

  test('empty frame window cannot be valid evidence', () {
    final report = QuranProfileRecorder().report(startUs: 10, endUs: 20);
    expect(report['sampleCount'], 0);
    expect(report['hasSamples'], isFalse);
    expect(report['meanTotalUs'], isNull);
    expect(report['validFrameWindow'], isFalse);
  });
}
