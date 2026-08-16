import 'package:flutter/material.dart';
import '../share_card_content.dart';
import '../social_share_model.dart';
import '../social_share_copy.dart';
import '../social_share_theme.dart';
import '../talia_share_tokens.dart';

/// Specialized share-card Template for Official Memorization Certificates.
/// (The certificate system itself is out of scope — this only renders share
/// data; every label around the Arabic award title is localized copy.)
class CertificateTemplate extends StatelessWidget {
  final SocialShareData data;
  final SocialShareTheme theme;
  final SocialShareFormat format;

  const CertificateTemplate({
    super.key,
    required this.data,
    required this.theme,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    final isCompact = format == SocialShareFormat.square;

    return ShareCardContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── 1. Golden Certified Seal Badge ───────────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: isCompact ? 54 : 66,
                height: isCompact ? 54 : 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accentColor.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: theme.accentColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              Container(
                width: isCompact ? 46 : 56,
                height: isCompact ? 46 : 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.accentColor,
                      TaliaShareColors.medalGold,
                      TaliaShareColors.deepGold,
                    ],
                  ),
                  border: Border.all(
                    color: TaliaShareColors.champagneGold,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: TaliaShareColors.medalInk,
                  size: 30,
                ),
              ),
            ],
          ),

          SizedBox(height: isCompact ? 6 : 10),

          // ─── 2. Certificate Title ─────────────────────────────────────────
          Text(
            data.title ?? copy.certificateTitle,
            textAlign: TextAlign.center,
            style: TaliaShareTypography.title(
              color: theme.accentColor,
              fontSize: isCompact ? 18 : 22,
            ),
          ),

          SizedBox(height: isCompact ? 4 : 8),

          // ─── 3. Award sentence (real award title embedded) ───────────────
          if (data.content.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                copy.certificateSentence(data.content),
                textAlign: TextAlign.center,
                style: TaliaShareTypography.body(
                  color: theme.textPrimary,
                  fontSize: isCompact ? 13 : 14.5,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),

          SizedBox(height: isCompact ? 8 : 12),

          // ─── 4. Verification Code Pill ────────────────────────────────────
          if (data.subtitle != null || data.verificationCode != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: theme.badgeBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.accentColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 13,
                    color: theme.accentColor,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      data.subtitle ??
                          copy.verificationCode(data.verificationCode ?? ''),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TaliaShareTypography.badge(
                        color: theme.badgeTextColor,
                        fontSize: isCompact ? 10.5 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
