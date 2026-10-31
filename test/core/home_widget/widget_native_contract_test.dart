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
  test(
    'receiver ships disabled and redraw alarms have a registered receiver',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final provider = RegExp(
        r'<receiver[^>]*TaliaHomeWidgetProvider[^>]*>',
      ).firstMatch(manifest)!.group(0)!;
      expect(provider, contains('android:enabled="false"'));
      expect(
        manifest,
        contains('es.antonborri.home_widget.HomeWidgetScheduledUpdateReceiver'),
      );
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
      expect(manifest, isNot(contains('supportsRtl')));
      final activity = File(
        'android/app/src/main/kotlin/com/talia/quran/MainActivity.kt',
      ).readAsStringSync();
      expect(activity, contains('talia/home_widget_component'));
      expect(activity, contains('isPinSupported'));
      expect(activity, contains('requestPin'));
      expect(activity, contains('setComponentEnabledSetting'));
      expect(activity, contains('DONT_KILL_APP'));
    },
  );
  test('RTL uses an Arabic layout with absolute gravity, not supportsRtl', () {
    final ltr = File(
      'android/app/src/main/res/layout/talia_home_widget.xml',
    ).readAsStringSync();
    final rtl = File(
      'android/app/src/main/res/layout/talia_home_widget_rtl.xml',
    ).readAsStringSync();
    expect(ltr, contains('android:gravity="left"'));
    expect(ltr, isNot(contains('android:gravity="right"')));
    expect(rtl, contains('android:gravity="right"'));
    expect(rtl, isNot(contains('android:gravity="left"')));
    for (final id in [
      'widget_prayer',
      'widget_review',
      'widget_wird',
      'widget_wird_range',
      'widget_wird_progress',
      'widget_wird_action',
      'widget_empty',
    ]) {
      expect(ltr, contains('@+id/$id'));
      expect(rtl, contains('@+id/$id'));
    }
    final provider = File(
      'android/app/src/main/kotlin/com/talia/quran/widget/TaliaHomeWidgetProvider.kt',
    ).readAsStringSync();
    expect(provider, contains('R.layout.talia_home_widget_rtl'));
    expect(provider, contains('createConfigurationContext'));
  });
  test(
    'widget strings exist in Arabic and English including the empty state',
    () {
      for (final path in [
        'android/app/src/main/res/values/widget_strings.xml',
        'android/app/src/main/res/values-ar/widget_strings.xml',
      ]) {
        final xml = File(path).readAsStringSync();
        expect(xml, contains('name="widget_empty_adult"'));
        expect(xml, contains('name="widget_empty_hint"'));
        expect(xml, contains('name="widget_stale"'));
        expect(xml, contains('name="widget_reviews_done"'));
        expect(xml, contains('name="widget_no_khatmah"'));
        expect(xml, contains('name="widget_prayer_unset"'));
        expect(xml, contains('name="widget_wird_action"'));
        expect(xml, contains('name="widget_preview_prayer"'));
      }
    },
  );
  test('Android 12 supplies a size map and the picker has its own preview', () {
    final provider = File(
      'android/app/src/main/kotlin/com/talia/quran/widget/TaliaHomeWidgetProvider.kt',
    ).readAsStringSync();
    final info = File(
      'android/app/src/main/res/xml/talia_home_widget_info.xml',
    ).readAsStringSync();
    expect(provider, contains('SizeF'));
    expect(provider, contains('responsiveViews'));
    expect(info, contains('android:minWidth="250dp"'));
    expect(info, contains('android:minResizeWidth="110dp"'));
    expect(info, contains('android:minResizeHeight="72dp"'));
    expect(info, contains('@layout/talia_home_widget_preview'));
    expect(
      File(
        'android/app/src/main/res/layout/talia_home_widget_preview.xml',
      ).existsSync(),
      isTrue,
    );
    for (final path in [
      'android/app/src/main/res/values/widget_colors.xml',
      'android/app/src/main/res/values-night/widget_colors.xml',
      'android/app/src/main/res/values-v31/widget_colors.xml',
      'android/app/src/main/res/values-night-v31/widget_colors.xml',
    ]) {
      final colors = File(path).readAsStringSync();
      expect(colors, contains('widget_background'));
      expect(colors, contains('widget_text_primary'));
    }
    expect(
      File(
        'android/app/src/main/res/values-v31/widget_colors.xml',
      ).readAsStringSync(),
      contains('system_accent1'),
    );
  });
}
