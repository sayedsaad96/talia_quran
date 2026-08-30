import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/quran/data/datasources/bookmark_service.dart';
import 'package:talia_quran/features/quran/domain/entities/bookmark_entry.dart';
import 'package:talia_quran/features/quran/presentation/pages/bookmarks_page.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => getIt.reset());

  testWidgets('bookmark list displays the complete Quran text without ellipsis', (
    tester,
  ) async {
    const sacredText =
        'إِنَّآ أَنزَلْنَٰهُ فِى لَيْلَةِ ٱلْقَدْرِ إِنَّآ أَنزَلْنَٰهُ فِى لَيْلَةِ ٱلْقَدْرِ إِنَّآ أَنزَلْنَٰهُ فِى لَيْلَةِ ٱلْقَدْرِ';
    final prefs = await SharedPreferences.getInstance();
    final service = BookmarkService(
      prefs,
      owner: const FixedRecordOwnerProvider('bookmark-widget-test'),
    );
    await service.toggle(
      BookmarkEntry(
        surahId: 97,
        surahName: 'القدر',
        ayahNumber: 1,
        ayahText: sacredText,
        savedAt: DateTime.utc(2026, 8, 25),
      ),
    );
    getIt.registerSingleton<BookmarkService>(service);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BookmarksTab()),
      ),
    );
    await tester.pumpAndSettle();

    final ayahText = tester.widget<Text>(find.text(sacredText));
    expect(ayahText.maxLines, isNull);
    expect(ayahText.overflow, isNot(TextOverflow.ellipsis));
  });
}
