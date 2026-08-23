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
export 'share_card_widgets.dart';
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
  /// When true, the user's name is hidden from the parchment footer.
  /// Useful for privacy-conscious sharing or when the user opts out.
  final bool hideUserName;

  const SocialShareCard({
    super.key,
    required this.data,
    required this.theme,
    this.width = TaliaShareDimensions.baseWidth,
    this.format = SocialShareFormat.portrait,
    this.hideUserName = false,
  });

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    // Apply the name toggle: when hidden, pass null to suppress the
    // "رحلة [الاسم] مع القرآن" line without mutating the source data object.
    final effectiveData = hideUserName
        ? data.copyWith(userName: null)
        : data;
    return ShareCardShell(
      data: effectiveData,
      theme: theme,
      format: format,
      width: width,
      copy: copy,
      child: ShareCardTemplateResolver.resolve(
        data: effectiveData,
        theme: theme,
        format: format,
      ),
    );
  }
}
