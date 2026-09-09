import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/resume_session_presentation_input.dart';
import 'package:talia_quran/core/journey/resume_session_presentation_mapper.dart';
import 'package:talia_quran/core/l10n/app_localizations_en.dart';

void main() {
  const mapper = ResumeSessionPresentationMapper();
  final l10n = AppLocalizationsEn();

  test('maps a quran page route to continue-reading copy', () {
    final data = mapper.map(
      ResumeSessionPresentationInput(
        route: '/quran/page/12',
        isArabic: false,
        l10n: l10n,
      ),
    );
    expect(data.title, 'Continue Quran Reading');
    expect(data.subtitle, 'Page 12');
    expect(data.route, '/quran/page/12');
  });

  test('maps a surah route to the surah name', () {
    final data = mapper.map(
      ResumeSessionPresentationInput(
        route: '/quran/surah/2',
        isArabic: false,
        l10n: l10n,
      ),
    );
    expect(data.title, 'Continue Surah Al-Baqarah');
    expect(data.subtitle, l10n.lastSavedReading);
  });

  test('falls back for unknown routes', () {
    final data = mapper.map(
      ResumeSessionPresentationInput(
        route: '/unknown',
        isArabic: false,
        l10n: l10n,
      ),
    );
    expect(data.title, l10n.resumeWhereYouLeft);
    expect(data.subtitle, l10n.savedPreviousActivity);
  });
}
