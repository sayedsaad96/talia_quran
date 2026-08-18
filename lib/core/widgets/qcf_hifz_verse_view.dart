import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;

import '../utils/quran_text_display_formatter.dart';
import '../theme/app_colors.dart';

// ─── Display Mode ─────────────────────────────────────────────────────────────

/// Controls which compact presentation variant the shared renderer uses.
/// Does NOT affect memorization logic.
enum HifzVerseDisplayMode {
  /// One verse — used by Hifz session, kids mode, and quiz answer result.
  single,

  /// Same-surah verse range — used by checkpoint or multi-verse review.
  range,

  /// List/tile-friendly view — used by daily plan cards.
  compact,

  /// Answer-result view — renders correct Quran text only; user text stays normal.
  comparison,
}

// ─── QcfHifzVerseView ─────────────────────────────────────────────────────────

/// A presentation-only widget that renders a Quran verse (or same-surah range)
/// using [qcf_quran_plus] with a mandatory [fallbackText] for graceful degradation.
///
/// ### Contract
/// - Never reads or writes memorization progress, repositories, Cubits, routes,
///   or JSON files.
/// - Never triggers navigation, audio, speech, evaluation, or Cubit events.
/// - Falls back to [fallbackText] when identity is invalid, QCF throws, or
///   QCF returns empty text.
/// - Locked verses ([isUnlocked] == false) render a lock indicator only —
///   the Quran text is NOT revealed.
/// - Memorized verses ([isMemorized] == true) receive a completed-style overlay.
/// - RTL direction is always preserved.
class QcfHifzVerseView extends StatelessWidget {
  const QcfHifzVerseView({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    this.endVerseNumber,
    required this.fallbackText,
    required this.isUnlocked,
    required this.isMemorized,
    this.displayMode = HifzVerseDisplayMode.single,
    this.textAlign = TextAlign.center,
  });

  /// Valid Quran surah number (1–114).
  final int surahNumber;

  /// First verse number to render.
  final int verseNumber;

  /// Optional last verse for range display; defaults to [verseNumber].
  /// Must be >= [verseNumber] when provided.
  final int? endVerseNumber;

  /// Existing JSON-backed verse text — always used when QCF cannot render.
  final String fallbackText;

  /// Copied from existing memorization logic. When false, the verse text is
  /// hidden and a lock indicator is rendered instead.
  final bool isUnlocked;

  /// Copied from existing memorization progress / review state. When true,
  /// a memorized-style treatment is applied.
  final bool isMemorized;

  /// Controls compact presentation variants. Default: [HifzVerseDisplayMode.single].
  final HifzVerseDisplayMode displayMode;

  /// Text alignment passed through to the rendered widget.
  final TextAlign textAlign;

  // ── Validation ──────────────────────────────────────────────────────────────

  bool get _isValidIdentity {
    if (surahNumber < 1 || surahNumber > 114) return false;
    if (verseNumber < 1) return false;
    final end = endVerseNumber ?? verseNumber;
    if (end < verseNumber) return false;
    return true;
  }

  // ── Font sizing ─────────────────────────────────────────────────────────────

  double get _fontSize => switch (displayMode) {
    HifzVerseDisplayMode.single => 26,
    HifzVerseDisplayMode.range => 24,
    HifzVerseDisplayMode.compact => 18,
    HifzVerseDisplayMode.comparison => 22,
  };

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Locked: show a lock indicator without revealing the verse.
    if (!isUnlocked) {
      return _LockedIndicator(isDark: _isDark(context));
    }

    // Memorized badge wrapper (renders verse, adds subtle overlay).
    return _MemorisedWrapper(
      isMemorized: isMemorized,
      child: _buildVerseContent(context),
    );
  }

  Widget _buildVerseContent(BuildContext context) {
    // Guard: validate verse identity before calling QCF helpers.
    if (!_isValidIdentity) {
      return _FallbackText(
        text: fallbackText,
        textAlign: textAlign,
        fontSize: _fontSize,
        isDark: _isDark(context),
      );
    }

    try {
      return _QcfContent(
        surahNumber: surahNumber,
        startVerse: verseNumber,
        endVerse: endVerseNumber ?? verseNumber,
        fallbackText: fallbackText,
        textAlign: textAlign,
        fontSize: _fontSize,
        isDark: _isDark(context),
      );
    } catch (_) {
      return _FallbackText(
        text: fallbackText,
        textAlign: textAlign,
        fontSize: _fontSize,
        isDark: _isDark(context),
      );
    }
  }

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

// ─── Formatting Helpers ───────────────────────────────────────────────────────

String _cleanVerseText(String verseText, int surahNumber, int verseNumber) {
  var trailingMarker = '';
  try {
    trailingMarker = qcf.getAyaNoQCFLite(surahNumber, verseNumber);
  } catch (_) {
    // Fall back to regex-only cleanup when the end marker cannot be resolved.
  }
  return QuranTextDisplayFormatter.cleanAyahForMemorization(
    verseText,
    trailingMarker: trailingMarker,
  );
}

// ─── QCF Content ──────────────────────────────────────────────────────────────

/// Renders one or more verses using qcf_quran_plus helpers inside a try/catch.
/// Falls back to [_FallbackText] when the package throws or returns empty text.
class _QcfContent extends StatelessWidget {
  const _QcfContent({
    required this.surahNumber,
    required this.startVerse,
    required this.endVerse,
    required this.fallbackText,
    required this.textAlign,
    required this.fontSize,
    required this.isDark,
  });

  final int surahNumber;
  final int startVerse;
  final int endVerse;
  final String fallbackText;
  final TextAlign textAlign;
  final double fontSize;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    try {
      final pageNumber = qcf.getPageNumber(surahNumber, startVerse);
      final textColor = isDark
          ? AppColors.darkTextPrimary
          : AppColors.lightTextPrimary;

      // Build inline span for single verse or same-surah range.
      final spans = <TextSpan>[];
      for (var verse = startVerse; verse <= endVerse; verse++) {
        final rawVerseText = qcf.getVerse(surahNumber, verse);

        // Guard: if QCF returns empty/null-like text, fall through to fallback.
        if (rawVerseText.isEmpty) {
          return _FallbackText(
            text: fallbackText,
            textAlign: textAlign,
            fontSize: fontSize,
            isDark: isDark,
          );
        }

        final cleanedVerseText = _cleanVerseText(
          rawVerseText,
          surahNumber,
          verse,
        );
        spans.add(TextSpan(text: '$cleanedVerseText '));
      }

      final qcfStyle = qcf.QuranTextStyles.qcfStyle(
        pageNumber: pageNumber,
        fontSize: fontSize,
        color: textColor,
      ).copyWith(height: 2.0);

      return Directionality(
        textDirection: TextDirection.rtl,
        child: Text.rich(
          TextSpan(children: spans),
          textAlign: textAlign,
          style: qcfStyle,
        ),
      );
    } catch (_) {
      return _FallbackText(
        text: fallbackText,
        textAlign: textAlign,
        fontSize: fontSize,
        isDark: isDark,
      );
    }
  }
}

// ─── Fallback Text ────────────────────────────────────────────────────────────

/// Renders the JSON-backed [fallbackText] with Amiri font and correct RTL
/// direction, matching the visual treatment of the former direct Text widgets.
class _FallbackText extends StatelessWidget {
  const _FallbackText({
    required this.text,
    required this.textAlign,
    required this.fontSize,
    required this.isDark,
  });

  final String text;
  final TextAlign textAlign;
  final double fontSize;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cleanedText = QuranTextDisplayFormatter.cleanAyahForMemorization(
      text,
    );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        cleanedText,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: fontSize,
          height: 2.0,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
        textAlign: textAlign,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

// ─── Locked Indicator ─────────────────────────────────────────────────────────

/// Shows a lock icon when the verse is not yet unlocked.
/// The Quran text is never revealed in locked state.
class _LockedIndicator extends StatelessWidget {
  const _LockedIndicator({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_rounded, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          'مقفل',
          style: TextStyle(fontFamily: 'Amiri', fontSize: 16, color: color),
        ),
      ],
    );
  }
}

// ─── Memorised Wrapper ────────────────────────────────────────────────────────

/// Adds a subtle memorized/completed visual treatment over the verse content.
/// When [isMemorized] is false, renders [child] as-is.
class _MemorisedWrapper extends StatelessWidget {
  const _MemorisedWrapper({required this.isMemorized, required this.child});

  final bool isMemorized;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isMemorized) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }
}
