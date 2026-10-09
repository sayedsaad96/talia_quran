import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/certificate/domain/certificate_verse.dart';

void main() {
  test('certificate verse is a verbatim word prefix of the canonical ayah', () {
    final quran =
        jsonDecode(File('assets/data/quran.json').readAsStringSync())
            as Map<String, dynamic>;
    final ayah = (quran['${CertificateVerse.surahId}'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((a) => a['verse'] == CertificateVerse.ayahNumber);
    final words = (ayah['text'] as String).split(' ');

    expect(
      CertificateVerse.text,
      words.take(CertificateVerse.wordCount).join(' '),
    );
  });
}
