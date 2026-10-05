import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations_ar.dart';
import 'package:talia_quran/core/l10n/app_localizations_en.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/family_dashboard.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/family_child_name.dart';

FamilyChildEntry _child(String name) =>
    FamilyChildEntry(childUserId: 'c1', displayName: name, isLocal: false);

void main() {
  test('an unnamed child shows the localized default', () {
    expect(_child('').shownName(AppLocalizationsEn()), 'My child');
    expect(_child('  ').shownName(AppLocalizationsAr()), 'طفلي');
  });

  test('a named child keeps its name in every language', () {
    expect(_child(' Maryam ').shownName(AppLocalizationsEn()), 'Maryam');
    expect(_child('مريم').shownName(AppLocalizationsAr()), 'مريم');
  });
}
