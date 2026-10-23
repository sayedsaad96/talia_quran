import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/constants/surah_names.dart';

void main() {
  test('native display allow-list is exactly the canonical surah names', () {
    final source = File(
      'android/app/src/main/kotlin/com/talia/quran/widget/WidgetSnapshotFormatter.kt',
    ).readAsStringSync();
    final section = source
        .split('canonicalSurahNames = setOf(')[1]
        .split(')')[0];
    final actual = RegExp(
      '"([^"]+)"',
    ).allMatches(section).map((match) => match[1]!).toSet();
    expect(actual, SurahNames.arabic.values.toSet());
  });
  test('native renderer remains synchronous in the application process', () {
    final source = File(
      'android/app/src/main/kotlin/com/talia/quran/widget/TaliaHomeWidgetProvider.kt',
    ).readAsStringSync();
    expect(source, contains('HomeWidgetPlugin.getData(context)'));
    expect(source, contains('appWidgetManager.updateAppWidget'));
    expect(source, isNot(contains('CoroutineScope')));
    expect(source, isNot(contains('goAsync(')));
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, isNot(contains('android:process=')));
  });
}
