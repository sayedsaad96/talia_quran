# Social Share Card Redesign ("Dawn") Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the ornament-heavy share cards with the approved "Dawn" system — content-first cards on Talia emerald with the golden mushaf light, the logo's arch as a hairline, the official logo once in a signature bar with an invitation line and a QR code, and Kufi numerals for stats.

**Architecture:** Keep the public data model, the sheet entry point, the 1080 px export and every caller. Add small focused units (palette + moods, links, backdrop, medal, signature bar, three hero widgets), then switch the shell/card/resolver/sheet to them in one task and delete the old theme, painters and templates in the next.

**Tech Stack:** Flutter 3.47 / Dart, `qr_flutter` 4.1 (already a dependency), `screenshot` (existing capture), bundled fonts Amiri, Noto Naskh Arabic, new Reem Kufi (variable TTF, OFL-1.1).

**Spec:** `docs/superpowers/specs/2026-09-28-social-share-card-redesign-design.md`

## Global Constraints

- Branch: all work on `feat/share-card-dawn` (created in Task 1). The working tree holds the owner's uncommitted changes: **never** `git add -A`/`git add .`; stage only the paths listed in each commit step. Never commit `test/design_system/` (untracked owner work).
- Format only files you edited: `dart format <file> ...`. Never format directories.
- Quran/azkar text is rendered exactly as `SocialShareData.content` / `subtitle` already carry it. No new religious text anywhere. Verse style stays `TaliaShareTypography.quranVerse` (Amiri). Reem Kufi is never applied to verse, dua or dhikr text.
- Design-token guard (`test/design_system/design_token_guard_test.dart`) scans `lib/core/widgets/**`: new files must contain **zero** `Color(0x`, `fontSize: <digit>`, `BorderRadius.circular(<digit>` and `isDark ?`. Literal colours live only in `share_card_palette.dart`; literal sizes/radii only in `talia_share_tokens.dart` (both exempt).
- Official logo asset: `assets/images/logo_new_padded.png` (already bundled via `assets/images/`). Shown exactly once per card.
- Landing URL: `SocialShareData.landingPageUrl` (`https://taliaapp.com`); QR = `https://taliaapp.com/?utm_source=talia_app&utm_medium=share_card&utm_campaign=<category.name>`.
- Export sizes unchanged: 1080×1350, 1080×1080, 1080×1920 (logical 360×450/360/640 at pixel ratio 3).
- Lints: `unawaited_futures`, `avoid_print`, `prefer_final_locals`.

## Spec refinements made while planning (owner-visible)

1. QR sizes raised for scannability (square 38, portrait 46, story 58 logical) with signature bars 46/54/66.
2. Dark signature "glass" is 70 % opaque (spec said 55 %) so text passes 4.5:1 over the brightest glow.
3. Ayah eyebrow is "آية قرآنية"/"Quran verse"; the reference line carries "سورة الإسراء · الآية 9" (avoids repeating the surah twice).
4. Khatmah card omits the long summary sentence (numbers already say it; the plain-text share still includes it). Certificate omits the "I earned…" sentence for the same reason.
5. Day palette accent is `#8A6414` (spec's `#B8862A` fails 4.5:1 on ivory); `#B8862A` is kept for the arch line.

## Review Focus

1. Ayat al-Kursi-length text on a square or story card — must be fully visible (scaled down), never clipped or overflowing. → Task 6 test.
2. Missing or zero stats (`streakDays` null, memorization `target` 0, wird `total` 0) — shows `0`, hides the progress line, no NaN/division errors. → Task 7 tests.
3. Very long user name, long achievement title, long English invitation — stay on their lines with ellipsis, no RenderFlex overflow. → Task 5 and Task 9 tests.
4. English locale with Arabic domain data (surah name, award title) — layout mirrors to LTR, Arabic data unchanged, English chrome ("Talia Quran"). → Task 9 test.
5. Kids card with long text — companion character is dropped so it never overlaps the text. → Task 9 test.

---

## File Structure

```
lib/core/widgets/social_share/
  share_card_palette.dart        NEW  SocialShareMood, SharePaletteId, SharePalette, SharePalettes
  share_card_links.dart          NEW  ShareCardLinks.forCategory
  share_card_backdrop.dart       NEW  ShareCardBackdrop, ShareArchPainter
  share_medal.dart               NEW  ShareMedal (8-point star)
  share_signature_bar.dart       NEW  ShareSignatureBar, ShareQrCode
  heroes/hero_parts.dart         NEW  HeroNumeral, HeroProgressLine
  heroes/text_hero.dart          NEW  TextHero (Quran, dua, dhikr)
  heroes/stat_hero.dart          NEW  StatHero (streak, memorization, progress, azkar wird)
  heroes/award_hero.dart         NEW  AwardHero (achievement, certificate, khatmah)
  share_card_shell.dart          REWRITE
  share_card_template_resolver.dart REWRITE
  social_share_card.dart         MODIFY (mood, exports)
  social_share_sheet.dart        MODIFY (mood chips, capture API)
  social_share_presentation.dart SIMPLIFY
  social_share_copy.dart         ADD then TRIM
  social_share_model.dart        ADD extension SocialShareDataKind
  talia_share_tokens.dart        ADD display font + TaliaShareMetrics, then TRIM
  social_share_theme.dart        DELETE (Task 10)
  share_card_widgets.dart        DELETE (Task 10)
  templates/                     DELETE (Task 10)
assets/fonts/Reem_Kufi/          NEW  ReemKufi-Variable.ttf, OFL.txt
pubspec.yaml                     ADD font family
test/assets/share_fonts_test.dart                              NEW
test/core/widgets/social_share/share_test_harness.dart         NEW
test/core/widgets/social_share/share_card_palette_test.dart    NEW
test/core/widgets/social_share/share_card_copy_links_test.dart NEW
test/core/widgets/social_share/share_card_primitives_test.dart NEW
test/core/widgets/social_share/share_signature_bar_test.dart   NEW
test/core/widgets/social_share/text_hero_test.dart             NEW
test/core/widgets/social_share/stat_hero_test.dart             NEW
test/core/widgets/social_share/award_hero_test.dart            NEW
test/core/widgets/social_share/share_card_render_test.dart     NEW
test/core/widgets/social_share_test.dart                       MODIFY
test/core/widgets/social_share_export_test.dart                MODIFY
```

---

### Task 1: Branch and bundle the Reem Kufi font

**Files:**
- Create: `assets/fonts/Reem_Kufi/ReemKufi-Variable.ttf`, `assets/fonts/Reem_Kufi/OFL.txt`
- Modify: `pubspec.yaml` (fonts section, after the `Noto_Naskh_Arabic` family)
- Test: `test/assets/share_fonts_test.dart`

**Interfaces:**
- Produces: font family name `Reem_Kufi` (used by `TaliaShareTypography.displayFontFamily` in Task 4).

- [ ] **Step 1: Create the branch**

```bash
git switch -c feat/share-card-dawn
```

- [ ] **Step 2: Write the failing test** — `test/assets/share_fonts_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const fontPath = 'assets/fonts/Reem_Kufi/ReemKufi-Variable.ttf';

  test('Reem Kufi ships with its OFL licence and a pubspec declaration', () {
    expect(File(fontPath).existsSync(), isTrue);
    expect(File('assets/fonts/Reem_Kufi/OFL.txt').existsSync(), isTrue);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: Reem_Kufi'));
    expect(pubspec, contains(fontPath));
  });

  test('Reem Kufi file is a TrueType font', () {
    final bytes = File(fontPath).readAsBytesSync();
    expect(bytes.sublist(0, 4), [0x00, 0x01, 0x00, 0x00]);
  });
}
```

- [ ] **Step 3: Run it to verify it fails**

Run: `flutter test test/assets/share_fonts_test.dart`
Expected: FAIL (file does not exist).

- [ ] **Step 4: Download the font (ask the owner for approval first — this downloads two files, ~127 KB + ~4 KB, from the official google/fonts GitHub repository)**

```bash
mkdir -p assets/fonts/Reem_Kufi
curl -fL -o assets/fonts/Reem_Kufi/ReemKufi-Variable.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/reemkufi/ReemKufi%5Bwght%5D.ttf"
curl -fL -o assets/fonts/Reem_Kufi/OFL.txt "https://raw.githubusercontent.com/google/fonts/main/ofl/reemkufi/OFL.txt"
```

- [ ] **Step 5: Declare the family in `pubspec.yaml`** — insert after the `Noto_Naskh_Arabic` family block (same indentation):

```yaml
    - family: Reem_Kufi
      fonts:
        - asset: assets/fonts/Reem_Kufi/ReemKufi-Variable.ttf
```

- [ ] **Step 6: Run the test and pub get**

Run: `flutter pub get` then `flutter test test/assets/share_fonts_test.dart`
Expected: PASS; `git diff --stat pubspec.lock` shows no change.

- [ ] **Step 7: Commit**

```bash
git add assets/fonts/Reem_Kufi/ReemKufi-Variable.ttf assets/fonts/Reem_Kufi/OFL.txt pubspec.yaml test/assets/share_fonts_test.dart
git commit -m "feat(share): bundle Reem Kufi display font"
```

---

### Task 2: Palettes and moods

**Files:**
- Create: `lib/core/widgets/social_share/share_card_palette.dart`
- Test: `test/core/widgets/social_share/share_card_palette_test.dart`

**Interfaces:**
- Produces:
  - `enum SocialShareMood { auto, night, day }`
  - `enum SharePaletteId { mushafLight, suhoor, dusk, sunrise, forenoon, kidsMorning, night, day }`
  - `class SharePalette` with `final` fields: `id`, `skyTop`, `skyMid`, `skyBase`, `glow` (Color), `glowStrength`, `glowRadius` (double), `textPrimary`, `textSecondary`, `textAccent`, `eyebrow`, `watermark`, `archLine`, `signatureSurface`, `signatureBorder`, `signatureText`, `wordmark`, `qrForeground`, `qrBackground` (Color).
  - `abstract final class SharePalettes` with the 8 `static const` palettes, `static const List<SharePalette> all`, `static SharePalette resolve(SocialShareData data, SocialShareMood mood)`, `static SharePalette forCategory(SocialShareCategory category)`.

- [ ] **Step 1: Write the failing test** — `test/core/widgets/social_share/share_card_palette_test.dart`

```dart
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The signature bar sits over the brightest part of the mushaf light.
Color _signatureBackdrop(SharePalette p) => Color.alphaBlend(
  p.signatureSurface,
  Color.lerp(p.skyBase, p.glow, p.glowStrength.clamp(0.0, 1.0))!,
);

void main() {
  SocialShareData dataFor(
    SocialShareCategory category, {
    SocialShareAudience audience = SocialShareAudience.adult,
  }) => SocialShareData(content: 'x', category: category, audience: audience);

  test('auto mood maps every category to its time-of-day palette', () {
    const expected = {
      SocialShareCategory.quranAyah: SharePaletteId.mushafLight,
      SocialShareCategory.dua: SharePaletteId.suhoor,
      SocialShareCategory.azkar: SharePaletteId.dusk,
      SocialShareCategory.achievement: SharePaletteId.sunrise,
      SocialShareCategory.certificate: SharePaletteId.sunrise,
      SocialShareCategory.khatmah: SharePaletteId.sunrise,
      SocialShareCategory.memorization: SharePaletteId.forenoon,
      SocialShareCategory.progress: SharePaletteId.forenoon,
      SocialShareCategory.streak: SharePaletteId.forenoon,
    };
    for (final category in SocialShareCategory.values) {
      expect(
        SharePalettes.resolve(dataFor(category), SocialShareMood.auto).id,
        expected[category],
        reason: '$category',
      );
    }
  });

  test('kids audience uses the morning palette only in auto mood', () {
    final kids = dataFor(
      SocialShareCategory.streak,
      audience: SocialShareAudience.kids,
    );
    expect(
      SharePalettes.resolve(kids, SocialShareMood.auto).id,
      SharePaletteId.kidsMorning,
    );
    expect(
      SharePalettes.resolve(kids, SocialShareMood.night).id,
      SharePaletteId.night,
    );
    expect(
      SharePalettes.resolve(kids, SocialShareMood.day).id,
      SharePaletteId.day,
    );
  });

  test('night and day moods override every category', () {
    for (final category in SocialShareCategory.values) {
      expect(
        SharePalettes.resolve(dataFor(category), SocialShareMood.night).id,
        SharePaletteId.night,
      );
      expect(
        SharePalettes.resolve(dataFor(category), SocialShareMood.day).id,
        SharePaletteId.day,
      );
    }
  });

  group('contrast', () {
    for (final p in SharePalettes.all) {
      test('${p.id}: body text is readable on the sky', () {
        expect(_contrast(p.textPrimary, p.skyMid), greaterThanOrEqualTo(4.5));
      });
      test('${p.id}: accent (numerals, references) is readable', () {
        expect(_contrast(p.textAccent, p.skyMid), greaterThanOrEqualTo(3.0));
      });
      test('${p.id}: signature text survives the brightest glow', () {
        expect(
          _contrast(p.signatureText, _signatureBackdrop(p)),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('${p.id}: QR modules contrast with their quiet zone', () {
        expect(_contrast(p.qrForeground, p.qrBackground), greaterThan(7));
      });
    }
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/widgets/social_share/share_card_palette_test.dart`
Expected: FAIL (`share_card_palette.dart` not found).

- [ ] **Step 3: Implement** — `lib/core/widgets/social_share/share_card_palette.dart`

```dart
import 'package:flutter/painting.dart';

import 'social_share_model.dart';

/// Looks offered in the share sheet. `auto` follows the shared content;
/// `night` and `day` force one look for every category.
enum SocialShareMood { auto, night, day }

enum SharePaletteId {
  mushafLight,
  suhoor,
  dusk,
  sunrise,
  forenoon,
  kidsMorning,
  night,
  day,
}

// Brand colours from the Talia logo and AppColors. Exported images never
// follow the device theme, so cards use these literals, not app tokens.
const _ink = Color(0xFF021210);
const _emeraldDeep = Color(0xFF042F2E);
const _emerald = Color(0xFF0D5C53);
const _emeraldLight = Color(0xFF148275);
const _mushafGlow = Color(0xFFFFCE6E);
const _ivoryText = Color(0xFFFFF8EC);
const _mistText = Color(0xFFD9E6E1);
const _gold = Color(0xFFF5C45A);
const _paper = Color(0xFFF0EDE6);
const _glass = Color(0xB3021210);
const _glassBorder = Color(0x73F5C45A);
const _archGold = Color(0x8CF5C45A);
const _whiteWatermark = Color(0x12FFFFFF);

/// Fixed colours for one exported card look.
@immutable
class SharePalette {
  const SharePalette({
    required this.id,
    required this.skyTop,
    required this.skyMid,
    required this.skyBase,
    required this.glow,
    required this.glowStrength,
    required this.glowRadius,
    required this.textPrimary,
    required this.textSecondary,
    required this.textAccent,
    required this.eyebrow,
    required this.watermark,
    required this.archLine,
    required this.signatureSurface,
    required this.signatureBorder,
    required this.signatureText,
    required this.wordmark,
    required this.qrForeground,
    required this.qrBackground,
  });

  /// Emerald night sky lit by the golden mushaf light from below.
  const SharePalette._dark({
    required this.id,
    required this.skyTop,
    required this.skyMid,
    required this.skyBase,
    this.glow = _mushafGlow,
    this.glowStrength = 0.85,
    this.glowRadius = 0.95,
    this.textPrimary = _ivoryText,
    this.textSecondary = _mistText,
    this.textAccent = _gold,
    this.eyebrow = _gold,
  }) : watermark = _whiteWatermark,
       archLine = _archGold,
       signatureSurface = _glass,
       signatureBorder = _glassBorder,
       signatureText = _paper,
       wordmark = _gold,
       qrForeground = _emeraldDeep,
       qrBackground = _paper;

  final SharePaletteId id;
  final Color skyTop;
  final Color skyMid;
  final Color skyBase;
  final Color glow;

  /// Opacity of the mushaf light at its centre (bottom of the card).
  final double glowStrength;

  /// Radial reach of the light, as a fraction of the card's shortest side.
  final double glowRadius;
  final Color textPrimary;
  final Color textSecondary;
  final Color textAccent;
  final Color eyebrow;
  final Color watermark;
  final Color archLine;
  final Color signatureSurface;
  final Color signatureBorder;
  final Color signatureText;
  final Color wordmark;
  final Color qrForeground;
  final Color qrBackground;
}

abstract final class SharePalettes {
  static const mushafLight = SharePalette._dark(
    id: SharePaletteId.mushafLight,
    skyTop: _ink,
    skyMid: _emeraldDeep,
    skyBase: _emerald,
  );

  /// Pre-dawn indigo hint — the time of supplication.
  static const suhoor = SharePalette._dark(
    id: SharePaletteId.suhoor,
    skyTop: Color(0xFF0B1530),
    skyMid: Color(0xFF062C35),
    skyBase: _emerald,
    glowStrength: 0.75,
  );

  /// Evening teal-blue for remembrance.
  static const dusk = SharePalette._dark(
    id: SharePaletteId.dusk,
    skyTop: Color(0xFF06202E),
    skyMid: Color(0xFF053338),
    skyBase: _emerald,
    glowStrength: 0.75,
  );

  /// Full sunrise for achievements, certificates and khatmah.
  static const sunrise = SharePalette._dark(
    id: SharePaletteId.sunrise,
    skyTop: _ink,
    skyMid: Color(0xFF0A3A33),
    skyBase: _emeraldLight,
    glowStrength: 1,
    glowRadius: 1.15,
  );

  static const forenoon = SharePalette._dark(
    id: SharePaletteId.forenoon,
    skyTop: _ink,
    skyMid: _emeraldDeep,
    skyBase: _emeraldLight,
  );

  static const kidsMorning = SharePalette._dark(
    id: SharePaletteId.kidsMorning,
    skyTop: _emerald,
    skyMid: _emeraldLight,
    skyBase: Color(0xFF1FA08E),
    glow: Color(0xFFFFD978),
    glowStrength: 1,
    glowRadius: 1.1,
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFFFFFFF),
    textAccent: Color(0xFFFFE9A8),
    eyebrow: Color(0xFFFFFFFF),
  );

  static const night = SharePalette._dark(
    id: SharePaletteId.night,
    skyTop: _ink,
    skyMid: _emeraldDeep,
    skyBase: _emerald,
    glowStrength: 0.55,
  );

  static const day = SharePalette(
    id: SharePaletteId.day,
    skyTop: Color(0xFFFDFCF8),
    skyMid: Color(0xFFFDFCF8),
    skyBase: Color(0xFFFBF3E2),
    glow: Color(0xFFF59E0B),
    glowStrength: 0.28,
    glowRadius: 0.95,
    textPrimary: Color(0xFF1A1209),
    textSecondary: Color(0xFF6B5E4E),
    textAccent: Color(0xFF8A6414),
    eyebrow: _emerald,
    watermark: Color(0x128A5A1A),
    archLine: Color(0x99B8862A),
    signatureSurface: _emeraldDeep,
    signatureBorder: _glassBorder,
    signatureText: _paper,
    wordmark: _gold,
    qrForeground: _emeraldDeep,
    qrBackground: _paper,
  );

  static const List<SharePalette> all = [
    mushafLight,
    suhoor,
    dusk,
    sunrise,
    forenoon,
    kidsMorning,
    night,
    day,
  ];

  static SharePalette resolve(SocialShareData data, SocialShareMood mood) {
    return switch (mood) {
      SocialShareMood.night => night,
      SocialShareMood.day => day,
      SocialShareMood.auto =>
        data.audience == SocialShareAudience.kids
            ? kidsMorning
            : forCategory(data.category),
    };
  }

  static SharePalette forCategory(SocialShareCategory category) {
    return switch (category) {
      SocialShareCategory.quranAyah => mushafLight,
      SocialShareCategory.dua => suhoor,
      SocialShareCategory.azkar => dusk,
      SocialShareCategory.achievement ||
      SocialShareCategory.certificate ||
      SocialShareCategory.khatmah => sunrise,
      SocialShareCategory.memorization ||
      SocialShareCategory.progress ||
      SocialShareCategory.streak => forenoon,
    };
  }
}
```

- [ ] **Step 4: Run the test**

Run: `flutter test test/core/widgets/social_share/share_card_palette_test.dart`
Expected: PASS. If a contrast test fails, darken only the failing colour in this file and note it in the commit message.

- [ ] **Step 5: Format and commit**

```bash
dart format lib/core/widgets/social_share/share_card_palette.dart test/core/widgets/social_share/share_card_palette_test.dart
git add lib/core/widgets/social_share/share_card_palette.dart test/core/widgets/social_share/share_card_palette_test.dart
git commit -m "feat(share): add Dawn palettes and share moods"
```

---

### Task 3: Share links, card copy and the wird-progress kind

**Files:**
- Create: `lib/core/widgets/social_share/share_card_links.dart`
- Modify: `lib/core/widgets/social_share/social_share_copy.dart` (add members; import palette), `lib/core/widgets/social_share/social_share_model.dart` (append extension at end of file)
- Test: `test/core/widgets/social_share/share_card_copy_links_test.dart`

**Interfaces:**
- Consumes: `SocialShareMood` (Task 2).
- Produces:
  - `abstract final class ShareCardLinks { static String forCategory(SocialShareCategory category) }`
  - `extension SocialShareDataKind on SocialShareData { bool get isAzkarWirdProgress }`
  - On `SocialShareCopy`: `factory SocialShareCopy.forLanguage(String languageCode)`, `String get wordmark`, `String eyebrow(SocialShareData data)`, `String? watermark(SocialShareData data)`, `String invitation(SocialShareData data)`, `String moodName(SocialShareMood mood)`, `String ayahReference(String? surahName, int? ayahNumber)`, `static String arabicCountWord(int n, {required String one, required String two, required String few, required String many})`, `String streakHeroLabel(int days)`, `String memorizedAyahsHeroLabel(int ayahs)`, `String surahsCompleted(int count)`, `String khatmahDaysLabel(int days)`, `String get wirdCompletedLabel`.

- [ ] **Step 1: Write the failing test** — `test/core/widgets/social_share/share_card_copy_links_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_links.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_copy.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';

void main() {
  final ar = SocialShareCopy.forLanguage('ar');
  final en = SocialShareCopy.forLanguage('en');

  group('ShareCardLinks', () {
    test('builds a campaign URL per category on the landing page', () {
      expect(
        ShareCardLinks.forCategory(SocialShareCategory.quranAyah),
        'https://taliaapp.com/?utm_source=talia_app&utm_medium=share_card&utm_campaign=quranAyah',
      );
    });

    test('never carries anything but the three campaign parameters', () {
      for (final c in SocialShareCategory.values) {
        final uri = Uri.parse(ShareCardLinks.forCategory(c));
        expect(uri.host, 'taliaapp.com');
        expect(uri.queryParameters.keys.toSet(), {
          'utm_source',
          'utm_medium',
          'utm_campaign',
        });
      }
    });
  });

  group('isAzkarWirdProgress', () {
    test('is true only for azkar with empty content', () {
      final wird = SocialShareData.azkarWird(
        categoryTitle: 'أذكار الصباح',
        completedCount: 3,
        totalCount: 10,
      );
      expect(wird.isAzkarWirdProgress, isTrue);
      const zikr = SocialShareData(
        content: 'سُبْحَانَ اللَّهِ',
        category: SocialShareCategory.azkar,
      );
      expect(zikr.isAzkarWirdProgress, isFalse);
      const dua = SocialShareData(content: '', category: SocialShareCategory.dua);
      expect(dua.isAzkarWirdProgress, isFalse);
    });
  });

  group('SocialShareCopy card copy', () {
    test('wordmark is localized', () {
      expect(ar.wordmark, 'تالية القرآن');
      expect(en.wordmark, 'Talia Quran');
    });

    test('every category has a non-empty invitation in both languages', () {
      for (final c in SocialShareCategory.values) {
        final data = SocialShareData(content: 'x', category: c);
        expect(ar.invitation(data), isNotEmpty, reason: '$c ar');
        expect(en.invitation(data), isNotEmpty, reason: '$c en');
      }
    });

    test('invitations follow the approved copy table', () {
      SocialShareData d(SocialShareCategory c, {String content = 'x'}) =>
          SocialShareData(content: content, category: c);
      expect(ar.invitation(d(SocialShareCategory.quranAyah)), 'شاركها… لعلّها تهدي قلبًا');
      expect(ar.invitation(d(SocialShareCategory.dua)), 'ادعُ بها لمن تحب');
      expect(ar.invitation(d(SocialShareCategory.azkar)), 'ذكّر بها من تحب');
      expect(ar.invitation(d(SocialShareCategory.azkar, content: '')), 'حافظ على أذكارك معي');
      expect(ar.invitation(d(SocialShareCategory.streak)), 'ابدأ وِردك اليوم');
      expect(ar.invitation(d(SocialShareCategory.khatmah)), 'ابدأ ختمتك القادمة');
      expect(en.invitation(d(SocialShareCategory.quranAyah)), 'Share it — it may guide a heart');
      const kids = SocialShareData(
        content: 'x',
        category: SocialShareCategory.quranAyah,
        audience: SocialShareAudience.kids,
      );
      expect(ar.invitation(kids), 'بطلٌ صغير يحفظ القرآن');
    });

    test('eyebrows name the content type', () {
      expect(
        ar.eyebrow(const SocialShareData(content: 'x', category: SocialShareCategory.quranAyah)),
        'آية قرآنية',
      );
      expect(
        ar.eyebrow(const SocialShareData(content: 'x', title: 'أذكار المساء', category: SocialShareCategory.azkar)),
        'ذِكر · أذكار المساء',
      );
      expect(
        ar.eyebrow(SocialShareData.azkarWird(categoryTitle: 'أذكار الصباح', completedCount: 1, totalCount: 2)),
        'أذكار الصباح',
      );
      expect(
        ar.eyebrow(const SocialShareData(content: 'x', category: SocialShareCategory.streak, audience: SocialShareAudience.kids)),
        'أبطال تالية الصغار',
      );
    });

    test('watermark is the surah name or a category word, never content', () {
      expect(
        ar.watermark(const SocialShareData(content: 'نص', surahName: 'الإسراء', category: SocialShareCategory.quranAyah)),
        'الإسراء',
      );
      expect(ar.watermark(const SocialShareData(content: 'نص', category: SocialShareCategory.dua)), 'دعاء');
      expect(ar.watermark(const SocialShareData(content: '', category: SocialShareCategory.azkar)), isNull);
      expect(ar.watermark(const SocialShareData(content: 'x', category: SocialShareCategory.streak)), isNull);
    });

    test('ayah reference combines surah and ayah number', () {
      expect(ar.ayahReference('الإسراء', 9), 'سورة الإسراء · الآية 9');
      expect(en.ayahReference('Al-Isra', 9), 'Surah Al-Isra · Ayah 9');
      expect(ar.ayahReference(null, null), 'القرآن الكريم');
    });

    test('Arabic count words follow number agreement', () {
      expect(ar.streakHeroLabel(1), 'يوم مع القرآن');
      expect(ar.streakHeroLabel(2), 'يومان مع القرآن');
      expect(ar.streakHeroLabel(7), 'أيام مع القرآن');
      expect(ar.streakHeroLabel(45), 'يومًا مع القرآن');
      expect(ar.memorizedAyahsHeroLabel(250), 'آيةً في صدري');
      expect(ar.surahsCompleted(2), '2 سورتان مكتملتان');
      expect(ar.surahsCompleted(12), '12 سورة مكتملة');
      expect(en.streakHeroLabel(1), 'day with the Quran');
      expect(en.streakHeroLabel(3), 'days with the Quran');
    });

    test('mood names are localized', () {
      expect(SocialShareMood.values.map(ar.moodName), ['تلقائي', 'ليل', 'نهار']);
      expect(SocialShareMood.values.map(en.moodName), ['Auto', 'Night', 'Day']);
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/widgets/social_share/share_card_copy_links_test.dart`
Expected: FAIL (missing files/members).

- [ ] **Step 3: Implement `share_card_links.dart`**

```dart
import 'social_share_model.dart';

/// The QR destination printed on every card. Only campaign parameters are
/// added; no user data ever enters the URL.
abstract final class ShareCardLinks {
  static String forCategory(SocialShareCategory category) {
    return Uri.parse(SocialShareData.landingPageUrl)
        .replace(
          path: '/',
          queryParameters: {
            'utm_source': 'talia_app',
            'utm_medium': 'share_card',
            'utm_campaign': category.name,
          },
        )
        .toString();
  }
}
```

- [ ] **Step 4: Append the extension to the end of `social_share_model.dart`** (after the `typedef` lines)

```dart

extension SocialShareDataKind on SocialShareData {
  /// Azkar wird completion shares carry counts only, never dhikr text.
  bool get isAzkarWirdProgress =>
      category == SocialShareCategory.azkar && content.trim().isEmpty;
}
```

- [ ] **Step 5: Add to `social_share_copy.dart`**

Add the import `import 'share_card_palette.dart';` below the existing imports. Add the factory right after `factory SocialShareCopy.of(...)`:

```dart
  /// Entry point outside a widget tree (tests, background export).
  factory SocialShareCopy.forLanguage(String languageCode) =>
      SocialShareCopy._(languageCode == 'ar');
```

Then add this section before `// ─── Share sheet chrome`:

```dart
  // ─── Dawn card copy ──────────────────────────────────────────────────────
  // App-authored invitation copy: no Quran, hadith or dua text lives here.
  String get wordmark => isArabic ? 'تالية القرآن' : 'Talia Quran';

  String eyebrow(SocialShareData data) {
    if (data.audience == SocialShareAudience.kids) {
      return isArabic ? 'أبطال تالية الصغار' : 'Little Talia champions';
    }
    final title = data.title?.trim() ?? '';
    switch (data.category) {
      case SocialShareCategory.quranAyah:
        return quranBadge;
      case SocialShareCategory.dua:
        return title.isEmpty ? duaBadge : '$duaBadge · $title';
      case SocialShareCategory.azkar:
        if (data.isAzkarWirdProgress) {
          return title.isEmpty ? dhikrBadge : title;
        }
        return title.isEmpty ? dhikrBadge : '$dhikrBadge · $title';
      case SocialShareCategory.achievement:
        return achievementBadge;
      case SocialShareCategory.memorization:
        return isArabic ? 'حفظ القرآن' : 'Memorization';
      case SocialShareCategory.streak:
        return isArabic ? 'استمرارية' : 'Streak';
      case SocialShareCategory.progress:
        return isArabic ? 'حصاد التقدم' : 'My progress';
      case SocialShareCategory.certificate:
        return isArabic ? 'شهادة إتمام' : 'Certificate';
      case SocialShareCategory.khatmah:
        return khatmahBadge;
    }
  }

  /// Faint background word for text cards: the surah name or a category
  /// word, never a fragment of Quran or azkar text.
  String? watermark(SocialShareData data) {
    switch (data.category) {
      case SocialShareCategory.quranAyah:
        return data.surahName;
      case SocialShareCategory.dua:
        return isArabic ? 'دعاء' : 'Dua';
      case SocialShareCategory.azkar:
        if (data.isAzkarWirdProgress) return null;
        return isArabic ? 'ذِكر' : 'Dhikr';
      default:
        return null;
    }
  }

  String invitation(SocialShareData data) {
    if (data.audience == SocialShareAudience.kids) {
      return isArabic
          ? 'بطلٌ صغير يحفظ القرآن'
          : 'A little champion memorizing Quran';
    }
    switch (data.category) {
      case SocialShareCategory.quranAyah:
        return isArabic
            ? 'شاركها… لعلّها تهدي قلبًا'
            : 'Share it — it may guide a heart';
      case SocialShareCategory.dua:
        return isArabic ? 'ادعُ بها لمن تحب' : 'Pray it for someone you love';
      case SocialShareCategory.azkar:
        if (data.isAzkarWirdProgress) {
          return isArabic ? 'حافظ على أذكارك معي' : 'Keep your adhkar with me';
        }
        return isArabic ? 'ذكّر بها من تحب' : 'Remind someone you love';
      case SocialShareCategory.achievement:
      case SocialShareCategory.progress:
        return isArabic ? 'رافقني في رحلتي مع القرآن' : 'Join my Quran journey';
      case SocialShareCategory.memorization:
        return isArabic
            ? 'احفظ معي… خطوة كل يوم'
            : 'Memorize with me, one step a day';
      case SocialShareCategory.streak:
        return isArabic ? 'ابدأ وِردك اليوم' : 'Start your daily wird today';
      case SocialShareCategory.certificate:
        return isArabic ? 'رحلة إتقان مع تالية' : 'A journey of mastery with Talia';
      case SocialShareCategory.khatmah:
        return isArabic ? 'ابدأ ختمتك القادمة' : 'Start your next khatmah';
    }
  }

  String moodName(SocialShareMood mood) {
    switch (mood) {
      case SocialShareMood.auto:
        return isArabic ? 'تلقائي' : 'Auto';
      case SocialShareMood.night:
        return isArabic ? 'ليل' : 'Night';
      case SocialShareMood.day:
        return isArabic ? 'نهار' : 'Day';
    }
  }

  String ayahReference(String? surahName, int? ayahNumber) {
    final surahPart = surahName == null ? holyQuran : surah(surahName);
    return ayahNumber == null ? surahPart : '$surahPart · ${ayah(ayahNumber)}';
  }

  /// Arabic noun agreement: 1, 2, 3–10, and 0 / 11+.
  static String arabicCountWord(
    int n, {
    required String one,
    required String two,
    required String few,
    required String many,
  }) {
    if (n == 1) return one;
    if (n == 2) return two;
    if (n >= 3 && n <= 10) return few;
    return many;
  }

  String streakHeroLabel(int days) => isArabic
      ? '${arabicCountWord(days, one: 'يوم', two: 'يومان', few: 'أيام', many: 'يومًا')} مع القرآن'
      : '${days == 1 ? 'day' : 'days'} with the Quran';

  String memorizedAyahsHeroLabel(int ayahs) => isArabic
      ? '${arabicCountWord(ayahs, one: 'آية', two: 'آيتان', few: 'آيات', many: 'آيةً')} في صدري'
      : '${ayahs == 1 ? 'ayah' : 'ayahs'} memorized';

  String surahsCompleted(int count) => isArabic
      ? '$count ${arabicCountWord(count, one: 'سورة مكتملة', two: 'سورتان مكتملتان', few: 'سور مكتملة', many: 'سورة مكتملة')}'
      : '$count ${count == 1 ? 'surah' : 'surahs'} completed';

  String khatmahDaysLabel(int days) => isArabic
      ? arabicCountWord(days, one: 'يوم', two: 'يومان', few: 'أيام', many: 'يومًا')
      : (days == 1 ? 'day' : 'days');

  String get wirdCompletedLabel => isArabic ? 'أذكار أتممتُها' : 'adhkar completed';
```

- [ ] **Step 6: Run the tests**

Run: `flutter test test/core/widgets/social_share/share_card_copy_links_test.dart test/core/widgets/social_share_test.dart`
Expected: PASS (existing tests unaffected).

- [ ] **Step 7: Format and commit**

```bash
dart format lib/core/widgets/social_share/share_card_links.dart lib/core/widgets/social_share/social_share_copy.dart lib/core/widgets/social_share/social_share_model.dart test/core/widgets/social_share/share_card_copy_links_test.dart
git add lib/core/widgets/social_share/share_card_links.dart lib/core/widgets/social_share/social_share_copy.dart lib/core/widgets/social_share/social_share_model.dart test/core/widgets/social_share/share_card_copy_links_test.dart
git commit -m "feat(share): add card copy, invitations and QR campaign links"
```

---

### Task 4: Display typography, metrics, backdrop and medal

**Files:**
- Modify: `lib/core/widgets/social_share/talia_share_tokens.dart` (add to `TaliaShareTypography`; add `TaliaShareMetrics` class after `TaliaShareSpacing`)
- Create: `lib/core/widgets/social_share/share_card_backdrop.dart`, `lib/core/widgets/social_share/share_medal.dart`
- Create: `test/core/widgets/social_share/share_test_harness.dart`
- Test: `test/core/widgets/social_share/share_card_primitives_test.dart`

**Interfaces:**
- Consumes: `SharePalette` (Task 2).
- Produces:
  - `TaliaShareTypography.displayFontFamily` (`'Reem_Kufi'`), `TaliaShareTypography.display({required Color color, double fontSize = 14, FontWeight fontWeight = FontWeight.w600, double height = 1.15, double letterSpacing = 0})`.
  - `TaliaShareMetrics` with fields `padding` (EdgeInsets), `eyebrowSize`, `signatureHeight`, `logoSize`, `qrSize`, `wordmarkSize`, `invitationSize`, `referenceSize`, `personalLineSize`, `numeralSize`, `numeralLabelSize`, `statNumeralSize`, `titleSize`, `bodySize`, `watermarkSize`, `characterHeight`, `heroInset`, `medalSize`, `gap` (double), `double verseSize(int length)`, `static TaliaShareMetrics of(SocialShareFormat)`, static consts `cardRadius`, `signatureRadius`, `qrRadius`, `barRadius`.
  - `ShareCardBackdrop({required SharePalette palette, required TaliaShareMetrics metrics, String? watermark})`; keys `share-mushaf-light`, `share-watermark`, `share-arch-hairline`.
  - `ShareArchPainter({required Color color, required double bottomInset})` with `static Path archPath(Size size, {required double bottomInset})`.
  - `ShareMedal({required double size, required Color color, required Widget child})`; key `share-medal` on its `SizedBox`.
  - Test helpers `shareHarness(...)`, `useCanvasView(tester)`.

- [ ] **Step 1: Create the shared test harness** — `test/core/widgets/social_share/share_test_harness.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Localized host for share widgets at a fixed logical size.
Widget shareHarness(
  Widget child, {
  Size size = const Size(320, 260),
  Locale locale = const Locale('ar'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: Center(
        child: SizedBox(width: size.width, height: size.height, child: child),
      ),
    ),
  );
}

/// Gives story canvases (360×640) room inside the test window.
void useCanvasView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
```

- [ ] **Step 2: Write the failing test** — `test/core/widgets/social_share/share_card_primitives_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_backdrop.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/share_medal.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/core/widgets/social_share/talia_share_tokens.dart';

import 'share_test_harness.dart';

void main() {
  group('TaliaShareMetrics', () {
    test('verse size shrinks with length in every format', () {
      for (final f in SocialShareFormat.values) {
        final m = TaliaShareMetrics.of(f);
        expect(m.verseSize(40), greaterThan(m.verseSize(120)));
        expect(m.verseSize(120), greaterThan(m.verseSize(200)));
        expect(m.verseSize(200), greaterThan(m.verseSize(400)));
      }
    });

    test('QR fits inside the signature bar', () {
      for (final f in SocialShareFormat.values) {
        final m = TaliaShareMetrics.of(f);
        expect(m.qrSize, lessThan(m.signatureHeight));
        expect(m.logoSize, lessThan(m.signatureHeight));
      }
    });

    test('display style is Reem Kufi with a matching weight variation', () {
      final style = TaliaShareTypography.display(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      );
      expect(style.fontFamily, 'Reem_Kufi');
      expect(style.fontVariations, [const FontVariation('wght', 700)]);
    });
  });

  group('ShareArchPainter', () {
    test('arch apex is centred and the path stays inside the card', () {
      const size = Size(360, 450);
      final path = ShareArchPainter.archPath(size, bottomInset: 80);
      final bounds = path.getBounds();
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(size.width));
      expect(bounds.top, closeTo(size.height * 0.09, 0.5));
      expect(bounds.bottom, closeTo(size.height - 80, 0.5));
      expect(bounds.center.dx, closeTo(size.width / 2, 0.5));
    });
  });

  group('ShareCardBackdrop', () {
    testWidgets('paints light, arch and the watermark when given', (
      tester,
    ) async {
      await tester.pumpWidget(
        shareHarness(
          ShareCardBackdrop(
            palette: SharePalettes.mushafLight,
            metrics: TaliaShareMetrics.of(SocialShareFormat.portrait),
            watermark: 'الإسراء',
          ),
          size: const Size(360, 450),
        ),
      );
      expect(find.byKey(const ValueKey('share-mushaf-light')), findsOneWidget);
      expect(find.byKey(const ValueKey('share-arch-hairline')), findsOneWidget);
      expect(find.text('الإسراء'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('omits the watermark when none is given', (tester) async {
      await tester.pumpWidget(
        shareHarness(
          ShareCardBackdrop(
            palette: SharePalettes.day,
            metrics: TaliaShareMetrics.of(SocialShareFormat.square),
          ),
          size: const Size(360, 360),
        ),
      );
      expect(find.byKey(const ValueKey('share-watermark')), findsNothing);
    });
  });

  testWidgets('ShareMedal wraps its child in the star', (tester) async {
    await tester.pumpWidget(
      shareHarness(
        const Center(
          child: ShareMedal(
            size: 80,
            color: Colors.amber,
            child: Icon(Icons.verified_rounded),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('share-medal')), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('share-medal'))), const Size(80, 80));
  });
}
```

- [ ] **Step 3: Run it to verify it fails**

Run: `flutter test test/core/widgets/social_share/share_card_primitives_test.dart`
Expected: FAIL (missing symbols).

- [ ] **Step 4: Add to `TaliaShareTypography`** in `talia_share_tokens.dart` (after `bodyFontFamily`, and a new method after `metricValue`)

```dart
  /// Reem Kufi — eyebrows, wordmark and numerals only. Never used for
  /// Quran, dua or dhikr text.
  static const String displayFontFamily = 'Reem_Kufi';
```

```dart
  /// Display style for the Kufi layer. The bundled font is variable, so
  /// the weight is also sent as a `wght` axis value.
  static TextStyle display({
    required Color color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.15,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: displayFontFamily,
      fontFamilyFallback: const [bodyFontFamily],
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontVariations: [FontVariation.weight(fontWeight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
```

- [ ] **Step 5: Add `TaliaShareMetrics`** after the `TaliaShareSpacing` class in `talia_share_tokens.dart`

```dart
/// Layout numbers for the Dawn card on its 360-wide logical canvas.
@immutable
class TaliaShareMetrics {
  const TaliaShareMetrics._({
    required this.padding,
    required this.eyebrowSize,
    required this.signatureHeight,
    required this.logoSize,
    required this.qrSize,
    required this.wordmarkSize,
    required this.invitationSize,
    required this.referenceSize,
    required this.personalLineSize,
    required this.numeralSize,
    required this.numeralLabelSize,
    required this.statNumeralSize,
    required this.titleSize,
    required this.bodySize,
    required this.watermarkSize,
    required this.characterHeight,
    required this.heroInset,
    required this.medalSize,
    required this.gap,
    required List<double> verseSizes,
  }) : _verseSizes = verseSizes;

  static const double cardRadius = 24;
  static const double signatureRadius = 12;
  static const double qrRadius = 4;
  static const double barRadius = 2;

  final EdgeInsets padding;
  final double eyebrowSize;
  final double signatureHeight;
  final double logoSize;
  final double qrSize;
  final double wordmarkSize;
  final double invitationSize;
  final double referenceSize;
  final double personalLineSize;
  final double numeralSize;
  final double numeralLabelSize;
  final double statNumeralSize;
  final double titleSize;
  final double bodySize;
  final double watermarkSize;
  final double characterHeight;
  final double heroInset;
  final double medalSize;
  final double gap;

  /// Verse sizes for text of ≤80, ≤150, ≤250 and more characters.
  final List<double> _verseSizes;

  double verseSize(int length) {
    if (length <= 80) return _verseSizes[0];
    if (length <= 150) return _verseSizes[1];
    if (length <= 250) return _verseSizes[2];
    return _verseSizes[3];
  }

  static const square = TaliaShareMetrics._(
    padding: EdgeInsets.all(16),
    eyebrowSize: 10,
    signatureHeight: 46,
    logoSize: 34,
    qrSize: 38,
    wordmarkSize: 11,
    invitationSize: 9,
    referenceSize: 11,
    personalLineSize: 10,
    numeralSize: 64,
    numeralLabelSize: 14,
    statNumeralSize: 26,
    titleSize: 16,
    bodySize: 12,
    watermarkSize: 56,
    characterHeight: 96,
    heroInset: 14,
    medalSize: 64,
    gap: 6,
    verseSizes: [21, 18, 15.5, 13],
  );

  static const portrait = TaliaShareMetrics._(
    padding: EdgeInsets.all(20),
    eyebrowSize: 11,
    signatureHeight: 54,
    logoSize: 40,
    qrSize: 46,
    wordmarkSize: 12.5,
    invitationSize: 10,
    referenceSize: 12,
    personalLineSize: 11,
    numeralSize: 84,
    numeralLabelSize: 16,
    statNumeralSize: 30,
    titleSize: 18,
    bodySize: 13,
    watermarkSize: 68,
    characterHeight: 128,
    heroInset: 18,
    medalSize: 80,
    gap: 8,
    verseSizes: [24, 21, 18, 15],
  );

  /// Story keeps clear of platform UI: 40 top, 56 bottom.
  static const story = TaliaShareMetrics._(
    padding: EdgeInsets.fromLTRB(24, 40, 24, 56),
    eyebrowSize: 13,
    signatureHeight: 66,
    logoSize: 48,
    qrSize: 58,
    wordmarkSize: 14,
    invitationSize: 11.5,
    referenceSize: 14,
    personalLineSize: 12.5,
    numeralSize: 112,
    numeralLabelSize: 19,
    statNumeralSize: 36,
    titleSize: 21,
    bodySize: 15,
    watermarkSize: 90,
    characterHeight: 170,
    heroInset: 22,
    medalSize: 104,
    gap: 12,
    verseSizes: [28, 25, 22, 18],
  );

  static TaliaShareMetrics of(SocialShareFormat format) {
    return switch (format) {
      SocialShareFormat.square => square,
      SocialShareFormat.portrait => portrait,
      SocialShareFormat.story => story,
    };
  }
}
```

(`talia_share_tokens.dart` already imports `package:flutter/material.dart` and `social_share_model.dart`; if `@immutable` is unresolved, it comes from `material.dart` via `foundation`.)

- [ ] **Step 6: Create `share_card_backdrop.dart`**

```dart
import 'package:flutter/material.dart';

import 'share_card_palette.dart';
import 'talia_share_tokens.dart';

/// Sky, golden mushaf light, optional watermark word and the logo's arch
/// as one hairline — the whole Dawn atmosphere, nothing else.
class ShareCardBackdrop extends StatelessWidget {
  const ShareCardBackdrop({
    super.key,
    required this.palette,
    required this.metrics,
    this.watermark,
  });

  final SharePalette palette;
  final TaliaShareMetrics metrics;
  final String? watermark;

  @override
  Widget build(BuildContext context) {
    final mark = watermark?.trim();
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.skyTop, palette.skyMid, palette.skyBase],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        DecoratedBox(
          key: const ValueKey('share-mushaf-light'),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.bottomCenter,
              radius: palette.glowRadius,
              colors: [
                palette.glow.withValues(alpha: palette.glowStrength),
                palette.glow.withValues(alpha: palette.glowStrength * 0.35),
                palette.glow.withValues(alpha: 0),
              ],
              stops: const [0, 0.4, 1],
            ),
          ),
        ),
        if (mark != null && mark.isNotEmpty)
          Align(
            alignment: const Alignment(0, -0.55),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: metrics.padding.left),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  mark,
                  key: const ValueKey('share-watermark'),
                  maxLines: 1,
                  style: TaliaShareTypography.display(
                    color: palette.watermark,
                    fontSize: metrics.watermarkSize,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        CustomPaint(
          key: const ValueKey('share-arch-hairline'),
          painter: ShareArchPainter(
            color: palette.archLine,
            bottomInset:
                metrics.signatureHeight + metrics.padding.bottom + metrics.gap,
          ),
        ),
      ],
    );
  }
}

/// The pointed mihrab arch from the Talia logo, as a single stroke.
class ShareArchPainter extends CustomPainter {
  const ShareArchPainter({required this.color, required this.bottomInset});

  final Color color;
  final double bottomInset;

  static Path archPath(Size size, {required double bottomInset}) {
    final left = size.width * 0.09;
    final right = size.width * 0.91;
    final w = right - left;
    final top = size.height * 0.09;
    final bottom = size.height - bottomInset;
    final shoulder = top + w * 0.46;
    double x(double f) => left + w * f;
    return Path()
      ..moveTo(left, bottom)
      ..lineTo(left, shoulder)
      ..quadraticBezierTo(left, top + w * 0.22, x(0.26), top + w * 0.14)
      ..quadraticBezierTo(x(0.46), top + w * 0.09, x(0.5), top)
      ..quadraticBezierTo(x(0.54), top + w * 0.09, x(0.74), top + w * 0.14)
      ..quadraticBezierTo(right, top + w * 0.22, right, shoulder)
      ..lineTo(right, bottom);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      archPath(size, bottomInset: bottomInset),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant ShareArchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bottomInset != bottomInset;
}
```

- [ ] **Step 7: Create `share_medal.dart`**

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Eight-point star medal used by achievement and certificate cards.
class ShareMedal extends StatelessWidget {
  const ShareMedal({
    super.key,
    required this.size,
    required this.color,
    required this.child,
  });

  final double size;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const ValueKey('share-medal'),
      dimension: size,
      child: CustomPaint(
        painter: _EightPointStarPainter(color: color),
        child: Center(
          child: SizedBox.square(
            dimension: size * 0.5,
            child: FittedBox(child: child),
          ),
        ),
      ),
    );
  }
}

class _EightPointStarPainter extends CustomPainter {
  const _EightPointStarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final half = size.shortestSide * 0.36;
    final square = Rect.fromCenter(center: c, width: half * 2, height: half * 2);
    final fill = Paint()..color = color.withValues(alpha: 0.12);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.02);
    for (final angle in const [0.0, math.pi / 4]) {
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..rotate(angle)
        ..translate(-c.dx, -c.dy)
        ..drawRect(square, fill)
        ..drawRect(square, stroke)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EightPointStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
```

- [ ] **Step 8: Run the tests**

Run: `flutter test test/core/widgets/social_share/share_card_primitives_test.dart test/core/widgets/social_share_test.dart`
Expected: PASS.

- [ ] **Step 9: Format and commit**

```bash
dart format lib/core/widgets/social_share/talia_share_tokens.dart lib/core/widgets/social_share/share_card_backdrop.dart lib/core/widgets/social_share/share_medal.dart test/core/widgets/social_share/share_test_harness.dart test/core/widgets/social_share/share_card_primitives_test.dart
git add lib/core/widgets/social_share/talia_share_tokens.dart lib/core/widgets/social_share/share_card_backdrop.dart lib/core/widgets/social_share/share_medal.dart test/core/widgets/social_share/share_test_harness.dart test/core/widgets/social_share/share_card_primitives_test.dart
git commit -m "feat(share): add Kufi display style, Dawn metrics, backdrop and medal"
```

---

### Task 5: Signature bar with logo and QR

**Files:**
- Create: `lib/core/widgets/social_share/share_signature_bar.dart`
- Test: `test/core/widgets/social_share/share_signature_bar_test.dart`

**Interfaces:**
- Consumes: `SharePalette`, `TaliaShareMetrics`, `TaliaShareTypography.display/body`, `SocialShareCopy.wordmark`.
- Produces:
  - `ShareSignatureBar({required SharePalette palette, required TaliaShareMetrics metrics, required SocialShareCopy copy, required String invitation, required String qrData})`, `static const String logoAsset = 'assets/images/logo_new_padded.png'`; keys `share-signature-bar`, `share-logo`, `share-invitation`.
  - `ShareQrCode({required String data, required double size, required Color foreground, required Color background})` with public `data`; key `share-qr`.

- [ ] **Step 1: Write the failing test** — `test/core/widgets/social_share/share_signature_bar_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/share_signature_bar.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_copy.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/core/widgets/social_share/talia_share_tokens.dart';

import 'share_test_harness.dart';

void main() {
  const url =
      'https://taliaapp.com/?utm_source=talia_app&utm_medium=share_card&utm_campaign=quranAyah';

  Widget bar(SocialShareFormat format, String languageCode, String invitation) {
    return ShareSignatureBar(
      palette: SharePalettes.mushafLight,
      metrics: TaliaShareMetrics.of(format),
      copy: SocialShareCopy.forLanguage(languageCode),
      invitation: invitation,
      qrData: url,
    );
  }

  testWidgets('shows the logo once, wordmark, invitation and the QR', (
    tester,
  ) async {
    await tester.pumpWidget(
      shareHarness(
        bar(SocialShareFormat.portrait, 'ar', 'شاركها… لعلّها تهدي قلبًا'),
        size: const Size(320, 54),
      ),
    );
    expect(find.byKey(const ValueKey('share-logo')), findsOneWidget);
    expect(find.text('تالية القرآن'), findsOneWidget);
    expect(find.text('شاركها… لعلّها تهدي قلبًا'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.widget<ShareQrCode>(find.byType(ShareQrCode)).data, url);
    final logo = tester.widget<Image>(find.byKey(const ValueKey('share-logo')));
    expect(
      (logo.image as ResizeImage).imageProvider,
      const AssetImage(ShareSignatureBar.logoAsset),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long English invitation ellipsizes on the square card', (
    tester,
  ) async {
    await tester.pumpWidget(
      shareHarness(
        bar(
          SocialShareFormat.square,
          'en',
          'A little champion memorizing Quran every single day with family',
        ),
        size: const Size(328, 46),
        locale: const Locale('en'),
      ),
    );
    final text = tester.widget<Text>(
      find.byKey(const ValueKey('share-invitation')),
    );
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/widgets/social_share/share_signature_bar_test.dart`
Expected: FAIL (file missing).

- [ ] **Step 3: Implement `share_signature_bar.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'share_card_palette.dart';
import 'social_share_copy.dart';
import 'talia_share_tokens.dart';

/// The only brand block on a card: official logo, wordmark, a gentle
/// invitation and a QR code to the landing page.
class ShareSignatureBar extends StatelessWidget {
  const ShareSignatureBar({
    super.key,
    required this.palette,
    required this.metrics,
    required this.copy,
    required this.invitation,
    required this.qrData,
  });

  static const String logoAsset = 'assets/images/logo_new_padded.png';

  final SharePalette palette;
  final TaliaShareMetrics metrics;
  final SocialShareCopy copy;
  final String invitation;
  final String qrData;

  @override
  Widget build(BuildContext context) {
    final inset = (metrics.signatureHeight - metrics.qrSize) / 2;
    return Container(
      key: const ValueKey('share-signature-bar'),
      height: metrics.signatureHeight,
      padding: EdgeInsets.symmetric(horizontal: inset + 2, vertical: inset),
      decoration: BoxDecoration(
        color: palette.signatureSurface,
        borderRadius: BorderRadius.circular(TaliaShareMetrics.signatureRadius),
        border: Border.all(color: palette.signatureBorder, width: 0.8),
      ),
      child: Row(
        children: [
          _ShareLogo(size: metrics.logoSize, fallbackColor: palette.wordmark),
          SizedBox(width: metrics.gap + 2),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.wordmark,
                  maxLines: 1,
                  style: TaliaShareTypography.display(
                    color: palette.wordmark,
                    fontSize: metrics.wordmarkSize,
                    height: 1.2,
                  ),
                ),
                Text(
                  invitation,
                  key: const ValueKey('share-invitation'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TaliaShareTypography.body(
                    color: palette.signatureText,
                    fontSize: metrics.invitationSize,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: metrics.gap),
          ShareQrCode(
            data: qrData,
            size: metrics.qrSize,
            foreground: palette.qrForeground,
            background: palette.qrBackground,
          ),
        ],
      ),
    );
  }
}

class _ShareLogo extends StatelessWidget {
  const _ShareLogo({required this.size, required this.fallbackColor});

  final double size;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    // The padded logo has a transparent margin; scaling inside the circle
    // lets the emblem, not the padding, fill the mark.
    const emblemScale = 1.35;
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: Transform.scale(
          scale: emblemScale,
          child: Image.asset(
            ShareSignatureBar.logoAsset,
            key: const ValueKey('share-logo'),
            fit: BoxFit.cover,
            cacheWidth: (size * 3 * emblemScale).round(),
            errorBuilder: (_, _, _) =>
                Icon(Icons.auto_awesome_rounded, color: fallbackColor),
          ),
        ),
      ),
    );
  }
}

/// QR with a light quiet zone so it scans after social-media compression.
class ShareQrCode extends StatelessWidget {
  const ShareQrCode({
    super.key,
    required this.data,
    required this.size,
    required this.foreground,
    required this.background,
  });

  final String data;
  final double size;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('share-qr'),
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.07),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TaliaShareMetrics.qrRadius),
      ),
      child: QrImageView(
        data: data,
        padding: EdgeInsets.zero,
        backgroundColor: background,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: foreground),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: foreground,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/core/widgets/social_share/share_signature_bar_test.dart`
Expected: PASS. If `logo.image` is not a `ResizeImage` (it is when `cacheWidth` is set), assert on `logo.image.toString()` containing `logo_new_padded.png` instead.

- [ ] **Step 5: Format and commit**

```bash
dart format lib/core/widgets/social_share/share_signature_bar.dart test/core/widgets/social_share/share_signature_bar_test.dart
git add lib/core/widgets/social_share/share_signature_bar.dart test/core/widgets/social_share/share_signature_bar_test.dart
git commit -m "feat(share): add signature bar with official logo and QR"
```

---

### Task 6: TextHero (Quran, dua, dhikr)

**Files:**
- Create: `lib/core/widgets/social_share/heroes/text_hero.dart`
- Test: `test/core/widgets/social_share/text_hero_test.dart`

**Interfaces:**
- Consumes: `ShareCardContent` (existing), `SocialShareCopy.ayahReference`, `TaliaShareMetrics.verseSize`, `SharePalette`.
- Produces: `TextHero({required SocialShareData data, required SharePalette palette, required TaliaShareMetrics metrics})`; keys `share-hero-text`, `share-reference`.

- [ ] **Step 1: Write the failing test** — `test/core/widgets/social_share/text_hero_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/heroes/text_hero.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/core/widgets/social_share/talia_share_tokens.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

import 'share_test_harness.dart';

void main() {
  const isra9 =
      'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ وَيُبَشِّرُ الْمُؤْمِنِينَ';
  const ayatAlKursi =
      'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
      'لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۚ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ '
      'يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ '
      'وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضِ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ';

  Widget hero(SocialShareData data, SocialShareFormat format) => TextHero(
    data: data,
    palette: SharePalettes.mushafLight,
    metrics: TaliaShareMetrics.of(format),
  );

  SocialShareData verse(String text, {String? translation}) =>
      SocialShareData.quranAyah(
        ayah: Ayah(
          number: 9,
          surahId: 17,
          text: text,
          numberInSurah: 9,
        ),
        surahName: 'الإسراء',
        translation: translation,
      );

  testWidgets('renders the verse verbatim in Amiri with its reference', (
    tester,
  ) async {
    await tester.pumpWidget(shareHarness(hero(verse(isra9), SocialShareFormat.portrait)));
    expect(find.text('﴿ $isra9 ﴾'), findsOneWidget);
    expect(find.text('سورة الإسراء · الآية 9'), findsOneWidget);
    final style = tester.widget<Text>(find.byKey(const ValueKey('share-hero-text'))).style!;
    expect(style.fontFamily, 'Amiri');
    expect(tester.takeException(), isNull);
  });

  testWidgets('English cards add the translation, Arabic cards do not', (
    tester,
  ) async {
    final data = verse(isra9, translation: 'Indeed, this Quran guides');
    await tester.pumpWidget(
      shareHarness(hero(data, SocialShareFormat.portrait), locale: const Locale('en')),
    );
    expect(find.textContaining('Indeed, this Quran guides'), findsOneWidget);
    expect(find.text('Surah الإسراء · Ayah 9'), findsOneWidget);

    await tester.pumpWidget(shareHarness(hero(data, SocialShareFormat.portrait)));
    expect(find.textContaining('Indeed, this Quran guides'), findsNothing);
  });

  testWidgets('dua keeps its text and approved reference verbatim', (
    tester,
  ) async {
    const text = 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.';
    const data = SocialShareData(
      content: text,
      subtitle: 'سورة البقرة - 201',
      category: SocialShareCategory.dua,
    );
    await tester.pumpWidget(shareHarness(hero(data, SocialShareFormat.portrait)));
    expect(find.text('« $text »'), findsOneWidget);
    expect(find.text('سورة البقرة - 201'), findsOneWidget);
  });

  for (final format in SocialShareFormat.values) {
    testWidgets('Ayat al-Kursi fits the $format hero without overflow', (
      tester,
    ) async {
      final canvas = format.exportLogicalSize;
      // The hero area is roughly the canvas minus eyebrow and signature.
      final heroSize = Size(canvas.width - 72, canvas.height * 0.52);
      await tester.pumpWidget(
        shareHarness(hero(verse(ayatAlKursi), format), size: heroSize),
      );
      expect(find.textContaining('وَهُوَ الْعَلِيُّ الْعَظِيمُ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/widgets/social_share/text_hero_test.dart`
Expected: FAIL (file missing).

- [ ] **Step 3: Implement `heroes/text_hero.dart`**

```dart
import 'package:flutter/material.dart';

import '../share_card_content.dart';
import '../share_card_palette.dart';
import '../social_share_copy.dart';
import '../social_share_model.dart';
import '../talia_share_tokens.dart';

/// Quran verse, dua or dhikr as the hero. The text is rendered exactly as
/// the data carries it; only the enclosing brackets are presentation.
class TextHero extends StatelessWidget {
  const TextHero({
    super.key,
    required this.data,
    required this.palette,
    required this.metrics,
  });

  final SocialShareData data;
  final SharePalette palette;
  final TaliaShareMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    final isQuran = data.category == SocialShareCategory.quranAyah;
    final text = isQuran ? '﴿ ${data.content} ﴾' : '« ${data.content} »';
    final reference = isQuran
        ? copy.ayahReference(data.surahName, data.ayahNumber)
        : data.subtitle;
    final translation = data.translation;
    final showTranslation =
        !copy.isArabic && translation != null && translation.isNotEmpty;

    return ShareCardContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            key: const ValueKey('share-hero-text'),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TaliaShareTypography.quranVerse(
              color: palette.textPrimary,
              fontSize: metrics.verseSize(data.content.length),
              fontWeight: FontWeight.w600,
              height: 1.85,
            ),
          ),
          if (showTranslation) ...[
            SizedBox(height: metrics.gap),
            Text(
              '“$translation”',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TaliaShareTypography.body(
                color: palette.textSecondary,
                fontSize: metrics.bodySize,
              ),
            ),
          ],
          if (reference != null && reference.isNotEmpty) ...[
            SizedBox(height: metrics.gap * 1.5),
            Text(
              reference,
              key: const ValueKey('share-reference'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TaliaShareTypography.badge(
                color: palette.textAccent,
                fontSize: metrics.referenceSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/core/widgets/social_share/text_hero_test.dart`
Expected: PASS.

- [ ] **Step 5: Format and commit**

```bash
dart format lib/core/widgets/social_share/heroes/text_hero.dart test/core/widgets/social_share/text_hero_test.dart
git add lib/core/widgets/social_share/heroes/text_hero.dart test/core/widgets/social_share/text_hero_test.dart
git commit -m "feat(share): add text hero for Quran, dua and dhikr cards"
```

---

### Task 7: StatHero (streak, memorization, progress, azkar wird)

**Files:**
- Create: `lib/core/widgets/social_share/heroes/hero_parts.dart`, `lib/core/widgets/social_share/heroes/stat_hero.dart`
- Test: `test/core/widgets/social_share/stat_hero_test.dart`

**Interfaces:**
- Consumes: copy members from Task 3 (`streakHeroLabel`, `memorizedAyahsHeroLabel`, `surahsCompleted`, `wirdCompletedLabel`) and existing `newRecord`, `longestStreak(int)`, `progress(int, int)`, `progressTitle`, `pagesReadLabel`, `ayahsMemorizedLabel`, `streakDaysLabel`; `SocialShareDataKind.isAzkarWirdProgress`.
- Produces:
  - `HeroNumeral({required String text, required Color color, required double size})`; key `share-hero-numeral`.
  - `HeroProgressLine({required double value, required SharePalette palette, required double width})`; key `share-progress-line`.
  - `StatHero({required SocialShareData data, required SharePalette palette, required TaliaShareMetrics metrics})`.

- [ ] **Step 1: Write the failing test** — `test/core/widgets/social_share/stat_hero_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/heroes/stat_hero.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/core/widgets/social_share/talia_share_tokens.dart';

import 'share_test_harness.dart';

void main() {
  Future<void> pump(WidgetTester tester, SocialShareData data) =>
      tester.pumpWidget(
        shareHarness(
          StatHero(
            data: data,
            palette: SharePalettes.forenoon,
            metrics: TaliaShareMetrics.portrait,
          ),
        ),
      );

  final progressLine = find.byKey(const ValueKey('share-progress-line'));

  testWidgets('streak at its record shows the new-record line', (tester) async {
    await pump(tester, SocialShareData.streak(streakDays: 45, longestStreak: 45));
    expect(find.text('45'), findsOneWidget);
    expect(find.text('يومًا مع القرآن'), findsOneWidget);
    expect(find.text('رقم قياسي جديد! 🎉'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('streak below its record shows the longest streak', (tester) async {
    await pump(tester, SocialShareData.streak(streakDays: 30, longestStreak: 45));
    expect(find.text('أطول سلسلة: 45 يوم'), findsOneWidget);
  });

  testWidgets('streak without values shows zero and no record line', (
    tester,
  ) async {
    await pump(
      tester,
      const SocialShareData(content: '', category: SocialShareCategory.streak),
    );
    expect(find.text('0'), findsOneWidget);
    expect(find.textContaining('أطول'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('memorization shows ayahs, surahs and progress to target', (
    tester,
  ) async {
    await pump(
      tester,
      SocialShareData.memorization(ayahsCount: 250, surahsCount: 12, targetAyahs: 500),
    );
    expect(find.text('250'), findsOneWidget);
    expect(find.text('آيةً في صدري'), findsOneWidget);
    expect(find.text('12 سورة مكتملة'), findsOneWidget);
    expect(find.text('250 من 500'), findsOneWidget);
    expect(progressLine, findsOneWidget);
  });

  testWidgets('memorization with a zero target hides the progress line', (
    tester,
  ) async {
    await pump(
      tester,
      SocialShareData.memorization(ayahsCount: 3, surahsCount: 0, targetAyahs: 0),
    );
    expect(progressLine, findsNothing);
    expect(find.textContaining('سورة'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress shows all three stats', (tester) async {
    await pump(
      tester,
      const SocialShareData(
        content: '',
        category: SocialShareCategory.progress,
        readPagesCount: 85,
        memorizedAyahsCount: 250,
        streakDays: 14,
      ),
    );
    for (final v in ['85', '250', '14']) {
      expect(find.text(v), findsOneWidget);
    }
    expect(find.text('صفحات مقروءة'), findsOneWidget);
    expect(find.text('آيات محفوظة'), findsOneWidget);
    expect(find.text('أيام متتالية'), findsOneWidget);
  });

  testWidgets('azkar wird progress shows counts and a line', (tester) async {
    await pump(
      tester,
      SocialShareData.azkarWird(categoryTitle: 'أذكار الصباح', completedCount: 12, totalCount: 15),
    );
    expect(find.text('12 / 15'), findsOneWidget);
    expect(find.text('أذكار أتممتُها'), findsOneWidget);
    expect(progressLine, findsOneWidget);
  });

  testWidgets('azkar wird with zero total shows the count only', (tester) async {
    await pump(
      tester,
      SocialShareData.azkarWird(categoryTitle: 'أذكار', completedCount: 0, totalCount: 0),
    );
    expect(find.text('0'), findsOneWidget);
    expect(progressLine, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/widgets/social_share/stat_hero_test.dart`
Expected: FAIL (files missing).

- [ ] **Step 3: Implement `heroes/hero_parts.dart`**

```dart
import 'package:flutter/material.dart';

import '../share_card_palette.dart';
import '../talia_share_tokens.dart';

/// Large Kufi numeral. Digits stay left-to-right in both locales so
/// values such as "12 / 15" read correctly.
class HeroNumeral extends StatelessWidget {
  const HeroNumeral({
    super.key,
    required this.text,
    required this.color,
    required this.size,
  });

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      key: const ValueKey('share-hero-numeral'),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: TaliaShareTypography.display(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.05,
      ),
    );
  }
}

/// Thin progress line; [value] is clamped to 0..1 by the caller.
class HeroProgressLine extends StatelessWidget {
  const HeroProgressLine({
    super.key,
    required this.value,
    required this.palette,
    required this.width,
  });

  final double value;
  final SharePalette palette;
  final double width;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(TaliaShareMetrics.barRadius);
    return Container(
      key: const ValueKey('share-progress-line'),
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: palette.textPrimary.withValues(alpha: 0.18),
        borderRadius: radius,
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: value,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.textAccent,
            borderRadius: radius,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement `heroes/stat_hero.dart`**

```dart
import 'package:flutter/material.dart';

import '../share_card_content.dart';
import '../share_card_palette.dart';
import '../social_share_copy.dart';
import '../social_share_model.dart';
import '../talia_share_tokens.dart';
import 'hero_parts.dart';

/// Kufi-numeral hero for streak, memorization, progress and azkar wird
/// cards. Every number comes from the data; nothing is computed here
/// beyond a clamped progress ratio.
class StatHero extends StatelessWidget {
  const StatHero({
    super.key,
    required this.data,
    required this.palette,
    required this.metrics,
  });

  final SocialShareData data;
  final SharePalette palette;
  final TaliaShareMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    final List<Widget> children;
    if (data.isAzkarWirdProgress) {
      children = _wird(copy);
    } else {
      children = switch (data.category) {
        SocialShareCategory.streak => _streak(copy),
        SocialShareCategory.memorization => _memorization(copy),
        SocialShareCategory.progress => _progress(copy),
        _ => const <Widget>[],
      };
    }
    return ShareCardContent(
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _numeral(String text) =>
      HeroNumeral(text: text, color: palette.textAccent, size: metrics.numeralSize);

  Widget _label(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: TaliaShareTypography.display(
      color: palette.textPrimary,
      fontSize: metrics.numeralLabelSize,
    ),
  );

  Widget _line(String text, Color color) => Padding(
    padding: EdgeInsets.only(top: metrics.gap),
    child: Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TaliaShareTypography.body(color: color, fontSize: metrics.bodySize),
    ),
  );

  Widget _bar(double ratio) => Padding(
    padding: EdgeInsets.only(top: metrics.gap * 1.5),
    child: HeroProgressLine(
      value: ratio.clamp(0.0, 1.0),
      palette: palette,
      width: metrics.numeralSize * 2.2,
    ),
  );

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  List<Widget> _streak(SocialShareCopy copy) {
    final days = data.streakDays ?? data.currentValue ?? 0;
    final longest = data.targetValue;
    final record =
        _nonEmpty(data.subtitle) ??
        (longest == null
            ? null
            : longest <= days
            ? copy.newRecord
            : copy.longestStreak(longest));
    final note = _nonEmpty(data.content);
    return [
      _numeral('$days'),
      _label(copy.streakHeroLabel(days)),
      if (record != null) _line(record, palette.textAccent),
      if (note != null) _line(note, palette.textSecondary),
    ];
  }

  List<Widget> _memorization(SocialShareCopy copy) {
    final ayahs = data.memorizedAyahsCount ?? data.currentValue ?? 0;
    final surahs = data.memorizedSurahsCount ?? 0;
    final target = data.targetValue ?? 0;
    final title = _nonEmpty(data.title);
    final subtitle = _nonEmpty(data.subtitle);
    final note = _nonEmpty(data.content);
    return [
      if (title != null)
        Padding(
          padding: EdgeInsets.only(bottom: metrics.gap),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TaliaShareTypography.display(
              color: palette.textPrimary,
              fontSize: metrics.titleSize,
            ),
          ),
        ),
      _numeral('$ayahs'),
      _label(copy.memorizedAyahsHeroLabel(ayahs)),
      if (target > 0) ...[
        _bar(ayahs / target),
        _line(copy.progress(ayahs, target), palette.textSecondary),
      ],
      if (surahs > 0) _line(copy.surahsCompleted(surahs), palette.textAccent),
      if (subtitle != null) _line(subtitle, palette.textSecondary),
      if (note != null) _line(note, palette.textSecondary),
    ];
  }

  List<Widget> _progress(SocialShareCopy copy) {
    final stats = [
      (data.readPagesCount ?? 0, copy.pagesReadLabel),
      (data.memorizedAyahsCount ?? 0, copy.ayahsMemorizedLabel),
      (data.streakDays ?? 0, copy.streakDaysLabel),
    ];
    return [
      Text(
        _nonEmpty(data.title) ?? copy.progressTitle,
        textAlign: TextAlign.center,
        style: TaliaShareTypography.display(
          color: palette.textPrimary,
          fontSize: metrics.titleSize,
        ),
      ),
      SizedBox(height: metrics.gap * 2),
      Row(
        children: [
          for (final (value, label) in stats)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HeroNumeral(
                    text: '$value',
                    color: palette.textAccent,
                    size: metrics.statNumeralSize,
                  ),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TaliaShareTypography.body(
                      color: palette.textSecondary,
                      fontSize: metrics.bodySize,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _wird(SocialShareCopy copy) {
    final completed = data.currentValue ?? 0;
    final total = data.targetValue ?? 0;
    return [
      _numeral(total > 0 ? '$completed / $total' : '$completed'),
      _label(copy.wirdCompletedLabel),
      if (total > 0) _bar(completed / total),
    ];
  }
}
```

- [ ] **Step 5: Run the tests**

Run: `flutter test test/core/widgets/social_share/stat_hero_test.dart`
Expected: PASS. (The progress stat test finds `'250'` once because only the progress card is pumped.)

- [ ] **Step 6: Format and commit**

```bash
dart format lib/core/widgets/social_share/heroes/hero_parts.dart lib/core/widgets/social_share/heroes/stat_hero.dart test/core/widgets/social_share/stat_hero_test.dart
git add lib/core/widgets/social_share/heroes/hero_parts.dart lib/core/widgets/social_share/heroes/stat_hero.dart test/core/widgets/social_share/stat_hero_test.dart
git commit -m "feat(share): add Kufi stat hero for streak, memorization, progress and wird"
```

---

### Task 8: AwardHero (achievement, certificate, khatmah)

**Files:**
- Create: `lib/core/widgets/social_share/heroes/award_hero.dart`
- Test: `test/core/widgets/social_share/award_hero_test.dart`

**Interfaces:**
- Consumes: `ShareMedal` (Task 4), `HeroNumeral` (Task 7), copy `completed`, `progress`, `achievementComplete`, `verificationCode(String)`, `pages(int)`, `khatmahDaysLabel(int)`.
- Produces: `AwardHero({required SocialShareData data, required SharePalette palette, required TaliaShareMetrics metrics})`.

- [ ] **Step 1: Write the failing test** — `test/core/widgets/social_share/award_hero_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/heroes/award_hero.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/core/widgets/social_share/talia_share_tokens.dart';

import 'share_test_harness.dart';

void main() {
  Future<void> pump(WidgetTester tester, SocialShareData data, {Size size = const Size(320, 260)}) =>
      tester.pumpWidget(
        shareHarness(
          AwardHero(data: data, palette: SharePalettes.sunrise, metrics: TaliaShareMetrics.portrait),
          size: size,
        ),
      );

  testWidgets('unlocked achievement shows medal, title and completion', (tester) async {
    await pump(
      tester,
      const SocialShareData(
        content: 'قرأت جزءاً كاملاً من القرآن الكريم',
        title: 'قارئ جزء كامل',
        category: SocialShareCategory.achievement,
        achievementIcon: '📖',
        currentValue: 20,
        targetValue: 20,
        achievementUnlocked: true,
      ),
    );
    expect(find.byKey(const ValueKey('share-medal')), findsOneWidget);
    expect(find.text('قارئ جزء كامل'), findsOneWidget);
    expect(find.text('مكتمل · 20 من 20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('locked achievement shows progress only', (tester) async {
    await pump(
      tester,
      const SocialShareData(
        content: 'x',
        title: 't',
        category: SocialShareCategory.achievement,
        currentValue: 5,
        targetValue: 20,
        achievementUnlocked: false,
      ),
    );
    expect(find.text('5 من 20'), findsOneWidget);
  });

  testWidgets('very long achievement title and description stay inside', (tester) async {
    await pump(
      tester,
      SocialShareData(
        content: 'وصف طويل جداً ' * 20,
        title: 'عنوان إنجاز طويل جداً ' * 6,
        category: SocialShareCategory.achievement,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('certificate shows the award title and verification code', (tester) async {
    await pump(
      tester,
      const SocialShareData(
        content: 'شهادة إتمام جزء عمّ',
        category: SocialShareCategory.certificate,
        verificationCode: 'TQ-2026-001',
      ),
    );
    expect(find.text('شهادة إتمام جزء عمّ'), findsOneWidget);
    expect(find.text('رقم التوثيق: TQ-2026-001'), findsOneWidget);
  });

  testWidgets('khatmah shows title, days, pages and dedication', (tester) async {
    await pump(
      tester,
      const SocialShareData(
        content: 'summary',
        title: 'ختمة رمضان',
        subtitle: 'مُهداة إلى والدتي',
        category: SocialShareCategory.khatmah,
        targetValue: 30,
        readPagesCount: 604,
      ),
    );
    expect(find.text('ختمة رمضان'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('يومًا'), findsOneWidget);
    expect(find.text('604 صفحة مقروءة'), findsOneWidget);
    expect(find.text('مُهداة إلى والدتي'), findsOneWidget);
    expect(find.text('summary'), findsNothing);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/widgets/social_share/award_hero_test.dart`
Expected: FAIL (file missing).

- [ ] **Step 3: Implement `heroes/award_hero.dart`**

```dart
import 'package:flutter/material.dart';

import '../share_card_content.dart';
import '../share_card_palette.dart';
import '../share_medal.dart';
import '../social_share_copy.dart';
import '../social_share_model.dart';
import '../talia_share_tokens.dart';
import 'hero_parts.dart';

/// Celebratory hero for achievements, certificates and a completed khatmah.
class AwardHero extends StatelessWidget {
  const AwardHero({
    super.key,
    required this.data,
    required this.palette,
    required this.metrics,
  });

  final SocialShareData data;
  final SharePalette palette;
  final TaliaShareMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    final children = switch (data.category) {
      SocialShareCategory.certificate => _certificate(copy),
      SocialShareCategory.khatmah => _khatmah(copy),
      _ => _achievement(copy),
    };
    return ShareCardContent(
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Widget _title(String text) => Text(
    text,
    textAlign: TextAlign.center,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: TaliaShareTypography.display(
      color: palette.textPrimary,
      fontSize: metrics.titleSize,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
  );

  Widget _line(String text, Color color, {int maxLines = 2}) => Padding(
    padding: EdgeInsets.only(top: metrics.gap),
    child: Text(
      text,
      textAlign: TextAlign.center,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TaliaShareTypography.body(color: color, fontSize: metrics.bodySize),
    ),
  );

  Widget _medal(Widget child) => Padding(
    padding: EdgeInsets.only(bottom: metrics.gap * 1.5),
    child: ShareMedal(size: metrics.medalSize, color: palette.textAccent, child: child),
  );

  List<Widget> _achievement(SocialShareCopy copy) {
    final icon = _nonEmpty(data.achievementIcon);
    final current = data.currentValue;
    final target = data.targetValue;
    final String status;
    if (current != null && target != null) {
      status = data.achievementUnlocked == false
          ? copy.progress(current, target)
          : '${copy.completed} · ${copy.progress(current, target)}';
    } else {
      status = copy.achievementComplete;
    }
    final title = _nonEmpty(data.title);
    final description = _nonEmpty(data.content);
    return [
      _medal(
        icon != null
            ? Text(
                icon,
                style: const TextStyle(
                  fontFamilyFallback: TaliaShareTypography.emojiFallback,
                ),
              )
            : Icon(Icons.emoji_events_rounded, color: palette.textAccent),
      ),
      if (title != null) _title(title),
      if (description != null)
        _line(description, palette.textSecondary, maxLines: 3),
      _line(status, palette.textAccent, maxLines: 1),
    ];
  }

  List<Widget> _certificate(SocialShareCopy copy) {
    final code = _nonEmpty(data.verificationCode);
    return [
      _medal(Icon(Icons.verified_rounded, color: palette.textAccent)),
      _title(data.content),
      if (code != null) _line(copy.verificationCode(code), palette.textAccent),
    ];
  }

  List<Widget> _khatmah(SocialShareCopy copy) {
    final title = _nonEmpty(data.title);
    final days = data.targetValue;
    final pages = data.readPagesCount;
    final dedication = _nonEmpty(data.subtitle);
    return [
      if (title != null) _title(title),
      if (days != null) ...[
        SizedBox(height: metrics.gap),
        HeroNumeral(text: '$days', color: palette.textAccent, size: metrics.numeralSize),
        Text(
          copy.khatmahDaysLabel(days),
          style: TaliaShareTypography.display(
            color: palette.textPrimary,
            fontSize: metrics.numeralLabelSize,
          ),
        ),
      ],
      if (pages != null) _line(copy.pages(pages), palette.textSecondary),
      if (dedication != null) _line(dedication, palette.textAccent),
    ];
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/core/widgets/social_share/award_hero_test.dart`
Expected: PASS.

- [ ] **Step 5: Format and commit**

```bash
dart format lib/core/widgets/social_share/heroes/award_hero.dart test/core/widgets/social_share/award_hero_test.dart
git add lib/core/widgets/social_share/heroes/award_hero.dart test/core/widgets/social_share/award_hero_test.dart
git commit -m "feat(share): add award hero for achievement, certificate and khatmah"
```

---

### Task 9: Switch the card, shell, resolver and sheet to moods

**Files:**
- Rewrite: `lib/core/widgets/social_share/share_card_shell.dart`, `lib/core/widgets/social_share/share_card_template_resolver.dart`
- Modify: `lib/core/widgets/social_share/social_share_card.dart`, `lib/core/widgets/social_share/social_share_presentation.dart`, `lib/core/widgets/social_share/social_share_sheet.dart`
- Modify tests: `test/core/widgets/social_share_test.dart`, `test/core/widgets/social_share_export_test.dart`
- Create test: `test/core/widgets/social_share/share_card_render_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 2–8.
- Produces:
  - `ShareCardShell({required SocialShareData data, required SharePalette palette, required SocialShareFormat format, required SocialShareCopy copy, required Widget child})`; keys `share-eyebrow`, `share-personal-line`, `share-hero-character`.
  - `ShareCardTemplateResolver.resolve({required SocialShareData data, required SharePalette palette, required SocialShareFormat format})`.
  - `SocialShareCard({required SocialShareData data, SocialShareMood mood = SocialShareMood.auto, double width, SocialShareFormat format, bool hideUserName})`.
  - `buildSocialShareCardCanvas({Key? key, required SocialShareData data, SocialShareMood mood = SocialShareMood.auto, required SocialShareFormat format, bool hideUserName = false})`.
  - `captureSocialShareCardImage({required BuildContext context, required SocialShareData data, SocialShareMood mood = SocialShareMood.auto, required SocialShareFormat format, bool hideUserName = false, ScreenshotController? controller})`.
  - Sheet mood chip keys `share-mood-auto|night|day`.
  - `enum SocialShareCharacterTreatment { none, prominent }`.

- [ ] **Step 1: Write the failing render test** — `test/core/widgets/social_share/share_card_render_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_card.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_sheet.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

import 'share_test_harness.dart';

const _isra9 =
    'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ وَيُبَشِّرُ الْمُؤْمِنِينَ';

SocialShareData _ayah({String? userName, SocialShareAudience audience = SocialShareAudience.adult, String text = _isra9}) =>
    SocialShareData.quranAyah(
      ayah: Ayah(number: 9, surahId: 17, text: text, numberInSurah: 9),
      surahName: 'الإسراء',
      userName: userName,
    ).copyWith(audience: audience);

SocialShareData _sampleFor(SocialShareCategory category) {
  switch (category) {
    case SocialShareCategory.quranAyah:
      return _ayah(userName: 'سيد');
    case SocialShareCategory.dua:
      return const SocialShareData(content: 'رَبِّ زِدْنِي عِلْمًا', subtitle: 'سورة طه - 114', category: SocialShareCategory.dua);
    case SocialShareCategory.azkar:
      return SocialShareData.azkarWird(categoryTitle: 'أذكار الصباح', completedCount: 12, totalCount: 15);
    case SocialShareCategory.achievement:
      return const SocialShareData(content: 'قرأت جزءاً كاملاً', title: 'قارئ جزء كامل', category: SocialShareCategory.achievement, achievementIcon: '📖');
    case SocialShareCategory.memorization:
      return SocialShareData.memorization(ayahsCount: 250, surahsCount: 12, targetAyahs: 500);
    case SocialShareCategory.streak:
      return SocialShareData.streak(streakDays: 45, longestStreak: 45, userName: 'سيد');
    case SocialShareCategory.progress:
      return const SocialShareData(content: '', category: SocialShareCategory.progress, readPagesCount: 85, memorizedAyahsCount: 250, streakDays: 14);
    case SocialShareCategory.certificate:
      return const SocialShareData(content: 'شهادة إتمام جزء عمّ', category: SocialShareCategory.certificate, verificationCode: 'TQ-1');
    case SocialShareCategory.khatmah:
      return const SocialShareData(content: 's', title: 'ختمة رمضان', category: SocialShareCategory.khatmah, targetValue: 30, readPagesCount: 604);
  }
}

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    SocialShareData data, {
    SocialShareMood mood = SocialShareMood.auto,
    SocialShareFormat format = SocialShareFormat.portrait,
    Locale locale = const Locale('ar'),
    bool hideUserName = false,
  }) async {
    useCanvasView(tester);
    await tester.pumpWidget(
      shareHarness(
        buildSocialShareCardCanvas(data: data, mood: mood, format: format, hideUserName: hideUserName),
        size: format.exportLogicalSize,
        locale: locale,
      ),
    );
  }

  testWidgets('ayah card: eyebrow, reference, watermark, one logo, invitation and QR', (tester) async {
    await pumpCard(tester, _ayah(userName: 'سيد'));
    expect(find.text('آية قرآنية'), findsOneWidget);
    expect(find.text('سورة الإسراء · الآية 9'), findsOneWidget);
    expect(find.byKey(const ValueKey('share-watermark')), findsOneWidget);
    expect(find.byKey(const ValueKey('share-logo')), findsOneWidget);
    expect(find.text('شاركها… لعلّها تهدي قلبًا'), findsOneWidget);
    expect(find.text('رحلة سيد مع القرآن'), findsOneWidget);
    expect(
      tester.widget<ShareQrCode>(find.byType(ShareQrCode)).data,
      ShareCardLinks.forCategory(SocialShareCategory.quranAyah),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hideUserName removes the personal line', (tester) async {
    await pumpCard(tester, _ayah(userName: 'سيد'), hideUserName: true);
    expect(find.byKey(const ValueKey('share-personal-line')), findsNothing);
  });

  testWidgets('a very long user name stays on one line', (tester) async {
    await pumpCard(tester, _ayah(userName: 'عبد الرحمن ' * 12), format: SocialShareFormat.square);
    final line = tester.widget<Text>(find.byKey(const ValueKey('share-personal-line')));
    expect(line.maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English cards mirror to LTR and use English chrome', (tester) async {
    await pumpCard(tester, _ayah(), locale: const Locale('en'));
    expect(find.text('Talia Quran'), findsOneWidget);
    expect(find.text('Share it — it may guide a heart'), findsOneWidget);
    final direction = Directionality.of(tester.element(find.byKey(const ValueKey('share-eyebrow'))));
    expect(direction, TextDirection.ltr);
    expect(find.text('﴿ $_isra9 ﴾'), findsOneWidget);
  });

  testWidgets('adult cards never show the companion character', (tester) async {
    await pumpCard(tester, _sampleFor(SocialShareCategory.achievement));
    expect(find.byKey(const ValueKey('share-hero-character')), findsNothing);
  });

  testWidgets('kids stat cards show the companion character', (tester) async {
    await pumpCard(tester, SocialShareData.streak(streakDays: 7).copyWith(audience: SocialShareAudience.kids));
    expect(find.byKey(const ValueKey('share-hero-character')), findsOneWidget);
    expect(find.text('أبطال تالية الصغار'), findsOneWidget);
  });

  testWidgets('kids card with long text drops the character', (tester) async {
    await pumpCard(tester, _ayah(audience: SocialShareAudience.kids, text: '$_isra9 $_isra9 $_isra9'));
    expect(find.byKey(const ValueKey('share-hero-character')), findsNothing);
  });

  testWidgets('verse text never uses the Kufi display font', (tester) async {
    await pumpCard(tester, _ayah());
    final style = tester.widget<Text>(find.byKey(const ValueKey('share-hero-text'))).style!;
    expect(style.fontFamily, isNot('Reem_Kufi'));
  });

  testWidgets('day mood resolves the day palette', (tester) async {
    await pumpCard(tester, _ayah(), mood: SocialShareMood.day);
    expect(tester.widget<ShareCardBackdrop>(find.byType(ShareCardBackdrop)).palette.id, SharePaletteId.day);
  });

  for (final category in SocialShareCategory.values) {
    for (final format in SocialShareFormat.values) {
      testWidgets('$category renders in $format across moods', (tester) async {
        for (final mood in SocialShareMood.values) {
          await pumpCard(tester, _sampleFor(category), mood: mood, format: format);
          expect(tester.takeException(), isNull, reason: '$category $format $mood');
          expect(find.byKey(const ValueKey('share-logo')), findsOneWidget);
        }
      });
    }
  }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/widgets/social_share/share_card_render_test.dart`
Expected: FAIL to compile (`mood` parameter does not exist).

- [ ] **Step 3: Rewrite `social_share_presentation.dart`**

```dart
import 'social_share_model.dart';

/// Whether the official companion appears on a card. Only kids cards show
/// it, and only when the text leaves room so it never overlaps content.
enum SocialShareCharacterTreatment { none, prominent }

abstract final class SocialSharePresentation {
  static SocialShareCharacterTreatment characterTreatmentFor(
    SocialShareData data, [
    SocialShareFormat format = SocialShareFormat.portrait,
  ]) {
    if (!data.showCharacter ||
        data.audience != SocialShareAudience.kids ||
        _prioritizesContent(data, format)) {
      return SocialShareCharacterTreatment.none;
    }
    return SocialShareCharacterTreatment.prominent;
  }

  static bool _prioritizesContent(
    SocialShareData data,
    SocialShareFormat format,
  ) {
    final textLoad =
        data.content.length +
        (data.title?.length ?? 0) +
        (data.subtitle?.length ?? 0) +
        (data.translation?.length ?? 0);
    final isTextHero =
        data.category == SocialShareCategory.quranAyah ||
        data.category == SocialShareCategory.dua ||
        (data.category == SocialShareCategory.azkar &&
            !data.isAzkarWirdProgress);
    final threshold = switch ((format, isTextHero)) {
      (SocialShareFormat.square, true) => 70,
      (SocialShareFormat.portrait, true) => 105,
      (SocialShareFormat.story, true) => 135,
      (SocialShareFormat.square, false) => 90,
      (SocialShareFormat.portrait, false) => 135,
      (SocialShareFormat.story, false) => 165,
    };
    return textLoad > threshold;
  }
}
```

- [ ] **Step 4: Rewrite `share_card_shell.dart`**

```dart
import 'package:flutter/material.dart';

import 'share_card_backdrop.dart';
import 'share_card_links.dart';
import 'share_card_palette.dart';
import 'share_signature_bar.dart';
import 'social_share_copy.dart';
import 'social_share_model.dart';
import 'social_share_presentation.dart';
import 'talia_share_tokens.dart';

/// The Dawn card frame: backdrop, content-type eyebrow, the hero [child],
/// an optional personal line and the signature bar.
class ShareCardShell extends StatelessWidget {
  const ShareCardShell({
    super.key,
    required this.data,
    required this.palette,
    required this.format,
    required this.copy,
    required this.child,
  });

  final SocialShareData data;
  final SharePalette palette;
  final SocialShareFormat format;
  final SocialShareCopy copy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final metrics = TaliaShareMetrics.of(format);
    final showCharacter =
        SocialSharePresentation.characterTreatmentFor(data, format) ==
        SocialShareCharacterTreatment.prominent;
    final characterLane = showCharacter ? metrics.characterHeight * 0.55 : 0.0;
    final name = data.userName?.trim();

    // Cards are exported offscreen where ambient Directionality is not
    // guaranteed; pin it to the copy so preview and PNG match.
    return Directionality(
      textDirection: copy.direction,
      child: AspectRatio(
        aspectRatio: TaliaShareDimensions.aspectRatioFor(format),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TaliaShareMetrics.cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShareCardBackdrop(
                palette: palette,
                metrics: metrics,
                watermark: copy.watermark(data),
              ),
              Padding(
                padding: metrics.padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      copy.eyebrow(data),
                      key: const ValueKey('share-eyebrow'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TaliaShareTypography.display(
                        color: palette.eyebrow,
                        fontSize: metrics.eyebrowSize,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          metrics.heroInset,
                          metrics.gap,
                          metrics.heroInset + characterLane,
                          metrics.gap,
                        ),
                        child: Center(child: child),
                      ),
                    ),
                    if (name != null && name.isNotEmpty) ...[
                      Text(
                        copy.journeyFor(name),
                        key: const ValueKey('share-personal-line'),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TaliaShareTypography.body(
                          color: palette.textSecondary,
                          fontSize: metrics.personalLineSize,
                        ),
                      ),
                      SizedBox(height: metrics.gap),
                    ],
                    ShareSignatureBar(
                      palette: palette,
                      metrics: metrics,
                      copy: copy,
                      invitation: copy.invitation(data),
                      qrData: ShareCardLinks.forCategory(data.category),
                    ),
                  ],
                ),
              ),
              if (showCharacter)
                PositionedDirectional(
                  end: metrics.padding.right - metrics.gap,
                  bottom:
                      metrics.padding.bottom +
                      metrics.signatureHeight +
                      metrics.gap,
                  child: TaliaCharacterHero(
                    assetPath: data.effectiveCharacterAssetPath,
                    height: metrics.characterHeight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The official companion art for kids cards.
class TaliaCharacterHero extends StatelessWidget {
  const TaliaCharacterHero({
    super.key,
    required this.assetPath,
    required this.height,
  });

  final String assetPath;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Both axes are pinned so offscreen exports lay out correctly before
    // the codec reports intrinsic dimensions.
    return Image.asset(
      assetPath,
      key: const ValueKey('share-hero-character'),
      width: height,
      height: height,
      fit: BoxFit.contain,
      cacheWidth: (height * 3).round(),
      errorBuilder: (_, _, _) => SizedBox.square(dimension: height),
    );
  }
}
```

- [ ] **Step 5: Rewrite `share_card_template_resolver.dart`**

```dart
import 'package:flutter/material.dart';

import 'heroes/award_hero.dart';
import 'heroes/stat_hero.dart';
import 'heroes/text_hero.dart';
import 'share_card_palette.dart';
import 'social_share_model.dart';
import 'talia_share_tokens.dart';

/// Picks the hero for a share category.
abstract final class ShareCardTemplateResolver {
  static Widget resolve({
    required SocialShareData data,
    required SharePalette palette,
    required SocialShareFormat format,
  }) {
    final metrics = TaliaShareMetrics.of(format);
    switch (data.category) {
      case SocialShareCategory.quranAyah:
      case SocialShareCategory.dua:
        return TextHero(data: data, palette: palette, metrics: metrics);
      case SocialShareCategory.azkar:
        return data.isAzkarWirdProgress
            ? StatHero(data: data, palette: palette, metrics: metrics)
            : TextHero(data: data, palette: palette, metrics: metrics);
      case SocialShareCategory.memorization:
      case SocialShareCategory.streak:
      case SocialShareCategory.progress:
        return StatHero(data: data, palette: palette, metrics: metrics);
      case SocialShareCategory.achievement:
      case SocialShareCategory.certificate:
      case SocialShareCategory.khatmah:
        return AwardHero(data: data, palette: palette, metrics: metrics);
    }
  }
}
```

- [ ] **Step 6: Rewrite `social_share_card.dart`**

```dart
import 'package:flutter/material.dart';

import 'share_card_palette.dart';
import 'share_card_shell.dart';
import 'share_card_template_resolver.dart';
import 'social_share_copy.dart';
import 'social_share_model.dart';
import 'talia_share_tokens.dart';

export 'heroes/award_hero.dart';
export 'heroes/stat_hero.dart';
export 'heroes/text_hero.dart';
export 'share_card_backdrop.dart';
export 'share_card_content.dart';
export 'share_card_links.dart';
export 'share_card_palette.dart';
export 'share_card_shell.dart';
export 'share_card_template_resolver.dart';
export 'share_medal.dart';
export 'share_signature_bar.dart';
export 'social_share_model.dart';
export 'social_share_presentation.dart';
export 'talia_share_tokens.dart';

/// Talia "Dawn" share card: the shared content as hero on the brand sky,
/// signed once with the official logo.
class SocialShareCard extends StatelessWidget {
  const SocialShareCard({
    super.key,
    required this.data,
    this.mood = SocialShareMood.auto,
    this.width = TaliaShareDimensions.baseWidth,
    this.format = SocialShareFormat.portrait,
    this.hideUserName = false,
  });

  final SocialShareData data;
  final SocialShareMood mood;
  final double width;
  final SocialShareFormat format;

  /// Hides the "رحلة [الاسم] مع القرآن" line for privacy.
  final bool hideUserName;

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    final effectiveData = hideUserName ? data.copyWith(userName: null) : data;
    final palette = SharePalettes.resolve(effectiveData, mood);
    return SizedBox(
      width: width,
      child: ShareCardShell(
        data: effectiveData,
        palette: palette,
        format: format,
        copy: copy,
        child: ShareCardTemplateResolver.resolve(
          data: effectiveData,
          palette: palette,
          format: format,
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Update `social_share_sheet.dart`**

7a. In `buildSocialShareCardCanvas` and `captureSocialShareCardImage`, replace the parameter `required SocialShareTheme theme,` with `SocialShareMood mood = SocialShareMood.auto,`; pass `mood: mood` where `theme: theme` was passed (in `SocialShareCard(...)` and in the inner `buildSocialShareCardCanvas(...)` call).

7b. In `_SocialShareSheetState`: replace `late SocialShareThemeType _selectedThemeType;` with `SocialShareMood _selectedMood = SocialShareMood.auto;` and add `bool _logoPrecached = false;`. Delete `initState` and the `_currentTheme` getter. Add:

```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Offscreen capture must not race the logo decode.
    if (_logoPrecached) return;
    _logoPrecached = true;
    unawaited(
      precacheImage(
        const AssetImage(ShareSignatureBar.logoAsset),
        context,
        onError: (_, _) {},
      ),
    );
  }
```

7c. In `_captureCardImage`, replace `theme: _currentTheme,` with `mood: _selectedMood,`. In the preview, replace `theme: _currentTheme,` with `mood: _selectedMood,` and the `ValueKey` string `'$_selectedThemeType-$_selectedFormat-$_showUserName'` with `'$_selectedMood-$_selectedFormat-$_showUserName'`.

7d. Add this method to `_SocialShareSheetState` (shared by format and mood chips so styling lives in one place):

```dart
  Widget _buildChoiceChip({
    Key? key,
    required Widget avatar,
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      key: key,
      avatar: avatar,
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        if (!value) return;
        unawaited(HapticFeedback.selectionClick());
        onSelected();
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      backgroundColor: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightSurfaceVariant,
      labelStyle: TextStyle(
        color: selected
            ? AppColors.primary
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        fontSize: 11,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : Colors.transparent,
      ),
    );
  }
```

7e. Replace the whole `ChoiceChip(...)` inside the format picker's `map` with:

```dart
                      child: _buildChoiceChip(
                        avatar: Icon(
                          fmt.icon,
                          size: 14,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                        ),
                        label: copy.formatName(fmt),
                        selected: isSelected,
                        isDark: isDark,
                        onSelected: () => setState(() => _selectedFormat = fmt),
                      ),
```

7f. Keep the `copy.chooseStyle` label. Replace the theme `SizedBox(height: 48, child: ListView.separated(...))` block with:

```dart
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: SocialShareMood.values.map((mood) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildChoiceChip(
                        key: ValueKey('share-mood-${mood.name}'),
                        avatar: _MoodSwatch(
                          palette: SharePalettes.resolve(widget.data, mood),
                        ),
                        label: copy.moodName(mood),
                        selected: mood == _selectedMood,
                        isDark: isDark,
                        onSelected: () => setState(() => _selectedMood = mood),
                      ),
                    );
                  }).toList(),
                ),
              ),
```

7g. Delete the `_ThemePreviewTile` class and add:

```dart
/// Tiny sky swatch previewing a mood's palette.
class _MoodSwatch extends StatelessWidget {
  const _MoodSwatch({required this.palette});

  final SharePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.skyTop, palette.skyBase, palette.glow],
        ),
        border: Border.all(color: palette.archLine),
      ),
    );
  }
}
```

- [ ] **Step 8: Migrate `test/core/widgets/social_share_test.dart`**

1. Delete the `characterImage` finder at the top of `main()`.
2. Delete the whole `group('Theme system', ...)` and the whole `group('Template Resolution & Widget Rendering', ...)` (each from its `group(` line through its matching closing `});`). Their behaviour is now covered by the hero tests and `share_card_render_test.dart`.
3. In `group('Share sheet chrome localization', ...)`, add to the English test: `expect(find.text('Auto'), findsOneWidget); expect(find.text('Night'), findsOneWidget); expect(find.text('Day'), findsOneWidget);` and add this test at the end of the group:

```dart
    testWidgets('choosing a mood re-renders the preview palette', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final data = SocialShareData.streak(streakDays: 12);
      await tester.pumpWidget(sheetHarness(data, const Locale('ar')));

      ShareCardBackdrop backdrop() =>
          tester.widget<ShareCardBackdrop>(find.byType(ShareCardBackdrop).last);
      expect(backdrop().palette.id, SharePaletteId.forenoon);

      await tester.ensureVisible(find.byKey(const ValueKey('share-mood-day')));
      await tester.tap(find.byKey(const ValueKey('share-mood-day')));
      await tester.pumpAndSettle();
      expect(backdrop().palette.id, SharePaletteId.day);
    });
```

- [ ] **Step 9: Migrate `test/core/widgets/social_share_export_test.dart`**

```bash
sed -i -E 's/theme: SocialShareTheme\.[A-Za-z]+,/mood: SocialShareMood.auto,/; s/required SocialShareTheme theme,/required SocialShareMood mood,/; s/^( *)theme: theme,/\1mood: mood,/' test/core/widgets/social_share_export_test.dart
```

Then by hand:
1. In `primeAssets`, add `'assets/images/logo_new_padded.png',` to the path list.
2. In `_loadRealFonts`, after the `Noto_Naskh_Arabic` load, add `await load('Reem_Kufi', ['assets/fonts/Reem_Kufi/ReemKufi-Variable.ttf']);`
3. Set these cases' mood: `04_quran_verse_en` → `SocialShareMood.day`; `07_streak_ar` → `SocialShareMood.night`; `17_certificate_ar` → `SocialShareMood.day`.
4. Append before the matrix test's closing `});`:

```dart
    await captureAndVerify(
      tester,
      caseName: '29_quran_day_story',
      data: SocialShareData.quranAyah(
        ayah: const Ayah(number: 9, surahId: 17, text: 'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ', numberInSurah: 9),
        surahName: 'الإسراء',
        userName: 'سيد',
      ),
      mood: SocialShareMood.day,
      format: SocialShareFormat.story,
    );

    await captureAndVerify(
      tester,
      caseName: '30_azkar_wird_night',
      data: SocialShareData.azkarWird(categoryTitle: 'أذكار الصباح', completedCount: 12, totalCount: 15),
      mood: SocialShareMood.night,
      format: SocialShareFormat.portrait,
    );

    await captureAndVerify(
      tester,
      caseName: '31_long_verse_square_night',
      data: SocialShareData.quranVerse(ayahText: ayatAlKursi, surahName: 'البقرة', ayahNumber: 255),
      mood: SocialShareMood.night,
      format: SocialShareFormat.square,
    );
```

(`ayatAlKursi` is already declared at the top of the matrix test.)

- [ ] **Step 10: Run the share tests and analyzer**

Run: `flutter analyze lib/core/widgets/social_share test/core/widgets` then `flutter test test/core/widgets test/assets/share_fonts_test.dart`
Expected: analyzer clean; all tests PASS (the old theme/template files still compile but are now unused — they are deleted in Task 10).

- [ ] **Step 11: Format and commit**

```bash
dart format lib/core/widgets/social_share/share_card_shell.dart lib/core/widgets/social_share/share_card_template_resolver.dart lib/core/widgets/social_share/social_share_card.dart lib/core/widgets/social_share/social_share_presentation.dart lib/core/widgets/social_share/social_share_sheet.dart test/core/widgets/social_share_test.dart test/core/widgets/social_share_export_test.dart test/core/widgets/social_share/share_card_render_test.dart
git add lib/core/widgets/social_share/share_card_shell.dart lib/core/widgets/social_share/share_card_template_resolver.dart lib/core/widgets/social_share/social_share_card.dart lib/core/widgets/social_share/social_share_presentation.dart lib/core/widgets/social_share/social_share_sheet.dart test/core/widgets/social_share_test.dart test/core/widgets/social_share_export_test.dart test/core/widgets/social_share/share_card_render_test.dart
git commit -m "feat(share): switch share cards to the Dawn shell and moods"
```

---

### Task 10: Delete the old theme, painters and templates

**Files:**
- Delete: `lib/core/widgets/social_share/social_share_theme.dart`, `lib/core/widgets/social_share/share_card_widgets.dart`, `lib/core/widgets/social_share/templates/` (all 7 files)
- Modify: `lib/core/widgets/social_share/talia_share_tokens.dart` (remove painters and unused colour/spacing classes), `lib/core/widgets/social_share/social_share_copy.dart` (remove unused members)

**Interfaces:**
- Produces: nothing new; the public surface is exactly what `social_share_card.dart` exports after Task 9.

- [ ] **Step 1: Confirm nothing references the old code**

Run:
```bash
grep -rnE "SocialShareTheme|social_share_theme|share_card_widgets|templates/|StatMedallion|GoldDivider|ShareStarOrnament|ShareLabelChip|OpenQuranEmblem|LanternEmblem" lib test --include=*.dart | grep -v "lib/core/widgets/social_share/templates/" | grep -v "lib/core/widgets/social_share/share_card_widgets.dart" | grep -v "lib/core/widgets/social_share/social_share_theme.dart"
```
Expected: no output. If anything appears, migrate it to the new API before deleting.

- [ ] **Step 2: Delete the files**

```bash
git rm lib/core/widgets/social_share/social_share_theme.dart lib/core/widgets/social_share/share_card_widgets.dart
git rm -r lib/core/widgets/social_share/templates
```

- [ ] **Step 3: Trim `talia_share_tokens.dart`**

Delete every `CustomPainter` class and `_SeededRandom` (from `/// Custom Painters for Luxury Islamic Framing & Geometry` to the end of the file). Then delete `TaliaShareColors` and `TaliaShareSpacing` if this returns nothing:

```bash
grep -rnE "TaliaShareColors|TaliaShareSpacing" lib test --include=*.dart | grep -v talia_share_tokens.dart
```

Keep `TaliaShareDimensions`, `TaliaShareTypography` and `TaliaShareMetrics`.

- [ ] **Step 4: Trim `social_share_copy.dart`**

For each of these members run `grep -rn "\.<name>\b" lib test --include=*.dart`; delete the member when the only hit is its declaration: `brandPromise`, `compactBrandPromise`, `appDomain`, `downloadCTA`, `downloadCTAShort`, `startJourney`, `kidsLabel`, `kidsEncouragement`, `memorizationBadge`, `streakBadge`, `progressBadge`, `certificateBadge`, `localizedBadge`, `memorizationTitle`, `ayahsLabel`, `surahsLabel`, `ayahs`, `surahs`, `streakTitle`, `consecutiveDays`, `quranCommitment`, `certificateTitle`, `certificateSentence`, `themeName`. Remove the `social_share_theme.dart` import.

- [ ] **Step 5: Run the analyzer, share tests and the design-token guard**

Run: `flutter analyze` then `flutter test test/core/widgets test/assets test/design_system/design_token_guard_test.dart`
Expected: analyzer clean; all PASS. If the guard fails, the failure names a file and metric — move the literal into `talia_share_tokens.dart` or `share_card_palette.dart` rather than raising the baseline. Do not edit or commit `test/design_system/design_token_baseline.json` (untracked owner file).

- [ ] **Step 6: Format and commit**

```bash
dart format lib/core/widgets/social_share/talia_share_tokens.dart lib/core/widgets/social_share/social_share_copy.dart
git add lib/core/widgets/social_share/talia_share_tokens.dart lib/core/widgets/social_share/social_share_copy.dart
git commit -m "refactor(share): remove legacy share themes, painters and templates"
```

(The `git rm` in Step 2 already staged the deletions; they land in this commit.)

---

### Task 11: Visual QA and full verification

**Files:**
- Possibly modify: `lib/core/widgets/social_share/talia_share_tokens.dart` (metrics), `lib/core/widgets/social_share/share_card_palette.dart` (colours) — only for issues found below.

- [ ] **Step 1: Render the QA matrix**

Run: `flutter test test/core/widgets/social_share_export_test.dart`
Expected: PASS and 31 PNGs in `build/share_qa/`.

- [ ] **Step 2: Review every PNG** (open each with an image viewer / the Read tool). Check, and write down each failure with its file name:
  - The hero is the largest element; nothing clipped; long verse (`11_long_verse`, `31_long_verse_square_night`) is fully readable.
  - Logo appears once, in the bar, and the emblem (arch + "تالية") is visible, not the dark padding.
  - QR has a light quiet zone on all four sides and is not cut off.
  - Watermark is faint and never competes with the verse.
  - Arch hairline ends above the signature bar and does not cross text.
  - Kids cards: character does not overlap numerals or text.
  - English cards (`02`, `04`, `18`, `20`, `23`) mirror correctly.
  - Day mood (`04`, `17`, `29`) text is dark on ivory; the bar is emerald.

- [ ] **Step 3: Scan-check the QR**

Open `build/share_qa/15_portrait_1080.png` on a monitor and scan it with a phone camera. Expected: opens `taliaapp.com` with the `utm_campaign=` parameter. If it does not scan, raise `qrSize` for that format in `TaliaShareMetrics` (and `signatureHeight` so `qrSize < signatureHeight`), then re-run Step 1.

- [ ] **Step 4: Fix findings** in tokens/palette only, re-run Step 1, re-review the affected PNGs.

- [ ] **Step 5: Full verification**

Run, in order:
```bash
flutter analyze
flutter test
```
Expected: analyzer reports no issues; the full suite passes (including `test/core/widgets/social_share_quran_exactness_test.dart` and `test/core/widgets/social_share/social_share_khatmah_test.dart`, unchanged).

- [ ] **Step 6: Commit any tuning**

```bash
dart format lib/core/widgets/social_share/talia_share_tokens.dart lib/core/widgets/social_share/share_card_palette.dart
git add lib/core/widgets/social_share/talia_share_tokens.dart lib/core/widgets/social_share/share_card_palette.dart
git commit -m "fix(share): tune Dawn card metrics after visual QA"
```

(Skip if Step 4 changed nothing.)

- [ ] **Step 7: Hand the owner the evidence** — list the reviewed PNGs (at least `03_quran_verse_ar`, `05_dua_ar`, `07_streak_ar`, `09_kids_achievement`, `25_khatmah_portrait`, `29_quran_day_story`, `30_azkar_wird_night`) and remind them the §4 invitation copy needs their sign-off before release.
