import 'package:flutter/material.dart';
import 'share_card_shell.dart';
import 'share_card_template_resolver.dart';
import 'social_share_model.dart';
import 'social_share_copy.dart';
import 'social_share_theme.dart';
import 'talia_share_tokens.dart';

export 'share_card_content.dart';
export 'share_card_shell.dart';
export 'share_card_template_resolver.dart';
export 'social_share_model.dart';
export 'social_share_theme.dart';
export 'talia_share_tokens.dart';

/// Talia Premium Dynamic Social Share Card
/// Renders specialized, content-driven layouts inside an authentic Islamic brand shell.
class SocialShareCard extends StatelessWidget {
  final SocialShareData data;
  final SocialShareTheme theme;
  final double width;
  final SocialShareFormat format;

  const SocialShareCard({
    super.key,
    required this.data,
    required this.theme,
    this.width = TaliaShareDimensions.baseWidth,
    this.format = SocialShareFormat.portrait,
  });

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    return ShareCardShell(
      data: data,
      theme: theme,
      format: format,
      width: width,
      copy: copy,
      child: ShareCardTemplateResolver.resolve(
        data: data,
        theme: theme,
        format: format,
      ),
    );
  }
}
