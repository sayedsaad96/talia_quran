import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/core/seasons/season_preferences.dart';
import 'package:talia_quran/features/settings/presentation/widgets/seasons_nav_subtitle.dart';

void main() {
  late SeasonPreferences seasons;

  Future<String?> subtitle(WidgetTester tester) async {
    String? out;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            out = seasonsNavSubtitle(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return out;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    seasons = SeasonPreferences(prefs, const FixedRecordOwnerProvider('a'));
    getIt.registerSingleton<SeasonPreferences>(seasons);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('master off gives the plain subtitle (null)', (tester) async {
    await seasons.setMasterEnabled(false);
    expect(await subtitle(tester), isNull);
  });

  testWidgets('hidden seasons are skipped, and the cache follows the choices', (
    tester,
  ) async {
    final initial = await subtitle(tester);
    for (final id in SeasonId.values) {
      await seasons.setSeasonEnabled(id, false);
    }
    expect(await subtitle(tester), isNull);
    await seasons.setMasterEnabled(false);
    expect(await subtitle(tester), isNull);
    await seasons.setMasterEnabled(true);
    for (final id in SeasonId.values) {
      await seasons.setSeasonEnabled(id, SeasonPreferences.defaultEnabled(id));
    }
    expect(await subtitle(tester), initial);
  });
}
