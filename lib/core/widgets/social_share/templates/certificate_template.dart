import 'package:flutter/material.dart';

import '../share_card_content.dart';
import '../social_share_copy.dart';
import '../social_share_model.dart';
import '../social_share_theme.dart';
import '../share_card_widgets.dart';
import '../talia_share_tokens.dart';

/// Specialized share-card Template for Official Memorization Certificates.
///
/// More ceremonial than everyday cards: a double gold frame with corner
/// star ornaments and a rayed verified seal. (The certificate system itself
/// is out of scope — this only renders share data; every label around the
/// Arabic award title is localized copy.)
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

    final gold = theme.accentColor;
    final sealSize = isCompact ? 48.0 : 58.0;

    return ShareCardContent(
      child: Stack(
        children: [
          // Double ceremonial gold frame.
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: gold.withValues(alpha: 0.85),
                width: 1.3,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(isCompact ? 8 : 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: gold.withValues(alpha: 0.38),
                  width: 0.8,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ─── 1. Rayed verified seal ────────────────────────────
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: sealSize * 1.8,
                        height: sealSize * 1.8,
                        child: CustomPaint(
                          painter: RadialRaysPainter(
                            color: gold,
                            opacity: 0.18,
                            rayCount: 14,
                          ),
                        ),
                      ),
                      Container(
                        width: sealSize * 1.16,
                        height: sealSize * 1.16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gold.withValues(alpha: 0.18),
                          boxShadow: [
                            BoxShadow(
                              color: gold.withValues(alpha: 0.35),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: sealSize,
                        height: sealSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              gold,
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

                  // ─── 2. Certificate Title ─────────────────────────────
                  Text(
                    data.title ?? copy.certificateTitle,
                    textAlign: TextAlign.center,
                    style: TaliaShareTypography.title(
                      color: gold,
                      fontSize: isCompact ? 18 : 22,
                    ),
                  ),

                  SizedBox(height: isCompact ? 4 : 8),

                  // ─── 3. Award sentence (real award title embedded) ────
                  if (data.content.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
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

                  // ─── 4. Verification code seal chip ───────────────────
                  if (data.subtitle != null || data.verificationCode != null)
                    ShareLabelChip(
                      icon: Icons.security_rounded,
                      accent: theme.accentColor,
                      background: theme.badgeBackground,
                      border: theme.borderColor,
                      isCompact: isCompact,
                      children: [
                        Flexible(
                          child: Text(
                            data.subtitle ??
                                copy.verificationCode(
                                  data.verificationCode ?? '',
                                ),
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
                ],
              ),
            ),
          ),

          // Corner star ornaments on the ceremonial frame.
          Positioned(
            top: 0,
            left: 0,
            child: ShareStarOrnament(
              color: gold.withValues(alpha: 0.85),
              size: isCompact ? 11 : 13,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: ShareStarOrnament(
              color: gold.withValues(alpha: 0.85),
              size: isCompact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
