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
      style: TaliaShareTypography.body(
        color: color,
        fontSize: metrics.bodySize,
      ),
    ),
  );

  Widget _medal(Widget child) => Padding(
    padding: EdgeInsets.only(bottom: metrics.gap * 1.5),
    child: ShareMedal(
      size: metrics.medalSize,
      color: palette.textAccent,
      child: child,
    ),
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
        HeroNumeral(
          text: '$days',
          color: palette.textAccent,
          size: metrics.numeralSize,
        ),
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
