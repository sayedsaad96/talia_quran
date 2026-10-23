import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// 300 ms PCM cue with a smooth envelope; contains no speech or Quran audio.
Uint8List feedbackTone(double frequency) {
  const rate = 22050;
  const samples = rate * 3 ~/ 10;
  final bytes = Uint8List(44 + samples * 2);
  final data = ByteData.sublistView(bytes);
  void text(int offset, String value) =>
      bytes.setRange(offset, offset + value.length, value.codeUnits);
  text(0, 'RIFF');
  data.setUint32(4, bytes.length - 8, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  text(36, 'data');
  data.setUint32(40, samples * 2, Endian.little);
  for (var i = 0; i < samples; i++) {
    final envelope = math.pow(math.sin(math.pi * i / (samples - 1)), 2);
    final value =
        (8192 * envelope * math.sin(2 * math.pi * frequency * i / rate))
            .round();
    data.setInt16(44 + i * 2, value, Endian.little);
  }
  return bytes;
}

Future<void> main() async {
  final directory = Directory('assets/audio/tones');
  await directory.create(recursive: true);
  await File('${directory.path}/correct.wav').writeAsBytes(feedbackTone(660));
  await File('${directory.path}/review.wav').writeAsBytes(feedbackTone(330));
}
