import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:talia_quran/core/utils/mushaf_hizb_helper.dart';

void main() {
  group('MushafHizbHelper.getHizb', () {
    test('matches the qcf package hizb header for every mushaf page', () {
      // The package computes the active hizb per page from the authentic
      // quarter table; the helper must agree on all 604 pages.
      for (var page = 1; page <= 604; page++) {
        final header = qcf.getCurrentHizbTextForPage(
          page,
          isArabic: false,
        );
        final match = RegExp(r'Hizb (\d+)$').firstMatch(header);
        expect(
          match,
          isNotNull,
          reason: 'package header for page $page was: "$header"',
        );
        expect(
          MushafHizbHelper.getHizb(page),
          int.parse(match!.group(1)!),
          reason: 'hizb mismatch on page $page',
        );
      }
    });

    test('returns a hizb within 1..60 for every page', () {
      for (var page = 1; page <= 604; page++) {
        final hizb = MushafHizbHelper.getHizb(page);
        expect(hizb, greaterThanOrEqualTo(1), reason: 'page $page');
        expect(hizb, lessThanOrEqualTo(60), reason: 'page $page');
      }
    });

    test('clamps out-of-range pages instead of throwing', () {
      expect(MushafHizbHelper.getHizb(0), 1);
      expect(MushafHizbHelper.getHizb(605), 60);
      expect(MushafHizbHelper.getHizb(700), 60);
    });
  });
}
