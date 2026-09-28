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
