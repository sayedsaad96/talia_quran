import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import '../../../../tool/generate_feedback_tones.dart';

void main() {
  test('generated feedback WAVs are bounded deterministic mono PCM', () {
    final correct = feedbackTone(660);
    final review = feedbackTone(330);
    final data = ByteData.sublistView(correct);
    expect(String.fromCharCodes(correct.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(correct.sublist(8, 12)), 'WAVE');
    expect(data.getUint16(20, Endian.little), 1);
    expect(data.getUint16(22, Endian.little), 1);
    expect(data.getUint16(34, Endian.little), 16);
    expect(data.getUint32(40, Endian.little), correct.length - 44);
    expect(
      (correct.length - 44) / 2 / data.getUint32(24, Endian.little),
      lessThan(1),
    );
    expect(correct, feedbackTone(660));
    expect(correct, isNot(review));
    expect(data.getInt16(44, Endian.little), 0);
    expect(data.getInt16(correct.length - 2, Endian.little), 0);
    final samples = [
      for (var i = 44; i < correct.length; i += 2)
        data.getInt16(i, Endian.little),
    ];
    expect(samples.any((s) => s != 0), isTrue);
    expect(samples.every((s) => s.abs() <= 8192), isTrue);
  });
}
