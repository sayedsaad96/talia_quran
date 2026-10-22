import 'package:flutter/widgets.dart';

import '../../../../core/constants/surah_names.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Human-readable ayah reference (surah name + ayah number) built from the
/// app's surah-name table; never shows the raw `surah:ayah` key.
String similarAyahLabel(BuildContext context, int surahId, int ayahNumber) {
  final name =
      (context.isArabic
          ? SurahNames.arabic[surahId]
          : SurahNames.english[surahId]) ??
      '';
  return context.l10n.surahAyahFormat(name, context.numText(ayahNumber));
}

/// Parses a validated `surah:ayah` key into a label; null when malformed.
String? similarAyahLabelForKey(BuildContext context, String key) {
  final parts = key.split(':');
  if (parts.length != 2) return null;
  final surah = int.tryParse(parts[0]);
  final ayah = int.tryParse(parts[1]);
  if (surah == null || ayah == null || surah < 1 || surah > 114 || ayah < 1) {
    return null;
  }
  return similarAyahLabel(context, surah, ayah);
}
