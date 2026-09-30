import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_time_context.dart';
import 'package:talia_quran/features/azkar/domain/services/smart_wird_general_policy.dart';

Zikr _zikr(String subcategory) => Zikr(
  id: 'z-$subcategory',
  text: 'نص',
  transliteration: '',
  translation: '',
  totalCount: 1,
  category: AzkarCategory.general,
  subcategory: subcategory,
);

void main() {
  test('situational subcategories never join a wird', () {
    for (final sub in SmartWirdGeneralPolicy.situational) {
      for (final period in AzkarPeriod.values) {
        expect(
          SmartWirdGeneralPolicy.includes(_zikr(sub), period),
          isFalse,
          reason: '$sub / $period',
        );
      }
    }
  });

  test('always-included subcategories join in both periods', () {
    for (final sub in SmartWirdGeneralPolicy.alwaysIncluded) {
      for (final period in AzkarPeriod.values) {
        expect(SmartWirdGeneralPolicy.includes(_zikr(sub), period), isTrue);
      }
    }
  });

  test('sleep azkar join only the evening period', () {
    final zikr = _zikr(SmartWirdGeneralPolicy.sleep);
    expect(SmartWirdGeneralPolicy.includes(zikr, AzkarPeriod.evening), isTrue);
    expect(SmartWirdGeneralPolicy.includes(zikr, AzkarPeriod.morning), isFalse);
  });

  test('waking azkar join only the morning period', () {
    final zikr = _zikr(SmartWirdGeneralPolicy.waking);
    expect(SmartWirdGeneralPolicy.includes(zikr, AzkarPeriod.morning), isTrue);
    expect(SmartWirdGeneralPolicy.includes(zikr, AzkarPeriod.evening), isFalse);
  });

  test('an empty or unknown subcategory is kept', () {
    expect(
      SmartWirdGeneralPolicy.includes(_zikr(''), AzkarPeriod.morning),
      isTrue,
    );
    expect(
      SmartWirdGeneralPolicy.includes(_zikr('تصنيف جديد'), AzkarPeriod.evening),
      isTrue,
    );
  });
}
