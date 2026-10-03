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

  Widget _numeral(String text) => HeroNumeral(
    text: text,
    color: palette.textAccent,
    size: metrics.numeralSize,
  );

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
      style: TaliaShareTypography.body(
        color: color,
        fontSize: metrics.bodySize,
      ),
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
      _numeral(copy.number(days)),
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
      _numeral(copy.number(ayahs)),
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
                    text: copy.number(value),
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
      _numeral(
        total > 0
            ? '${copy.number(completed)} / ${copy.number(total)}'
            : copy.number(completed),
      ),
      _label(copy.wirdCompletedLabel),
      if (total > 0) _bar(completed / total),
    ];
  }
}
