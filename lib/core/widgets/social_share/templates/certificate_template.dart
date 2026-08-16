import 'package:flutter/material.dart';
import '../social_share_model.dart';
import '../social_share_theme.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Official Memorization Certificates
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
    final isCompact = format == SocialShareFormat.square;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
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
                      const Color(0xFFD4AF37),
                      const Color(0xFF8B6508),
                    ],
                  ),
                  border: Border.all(
                    color: TaliaShareColors.champagneGold,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF2C1E03),
                  size: 30,
                ),
              ),
            ],
          ),

          SizedBox(height: isCompact ? 6 : 10),

          // ─── 2. Certificate Title ─────────────────────────────────────────
          Text(
            data.title ?? 'شهادة إتمام ومواظبة',
            textAlign: TextAlign.center,
            style: TaliaShareTypography.title(
              color: theme.accentColor,
              fontSize: isCompact ? 18 : 22,
            ),
          ),

          SizedBox(height: isCompact ? 4 : 8),

          // ─── 3. Content ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              data.content,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
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
                  Text(
                    data.subtitle ?? 'رقم التوثيق: ${data.verificationCode}',
                    style: TaliaShareTypography.badge(
                      color: theme.badgeTextColor,
                      fontSize: isCompact ? 10.5 : 12,
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
