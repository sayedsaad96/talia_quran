import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'privacy_policy_content.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final locale = Localizations.localeOf(context);
    final isAr = locale.languageCode == 'ar';

    final sections = isAr
        ? PrivacyPolicyContent.getArabicContent()
        : PrivacyPolicyContent.getEnglishContent();

    final effectiveDate = isAr
        ? PrivacyPolicyContent.arEffectiveDate
        : PrivacyPolicyContent.enEffectiveDate;

    final introSubtitle = isAr
        ? PrivacyPolicyContent.arIntroSubtitle
        : PrivacyPolicyContent.enIntroSubtitle;

    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final dividerColor = isDark
        ? AppColors.darkDivider
        : AppColors.lightDivider;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context, isDark, isAr),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                120,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.heroGradientDark
                          : AppColors.heroGradientLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          effectiveDate,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          introSubtitle,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Sections
                  ...sections.map((section) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(color: dividerColor, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: AppTypography.titleMedium.copyWith(
                              color: primary,
                              fontWeight: FontWeight.bold,
                              fontFamily: isAr ? 'Noto_Naskh_Arabic' : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...section.paragraphs.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                p,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: textColor,
                                  height: 1.6,
                                  fontFamily: isAr ? 'Noto_Naskh_Arabic' : null,
                                ),
                              ),
                            ),
                          ),
                          if (section.bullets.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            ...section.bullets.map(
                              (bullet) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: 6.0,
                                        left: isAr ? 0 : 8.0,
                                        right: isAr ? 8.0 : 0,
                                      ),
                                      child: Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: primary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        bullet,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              color: textColor,
                                              height: 1.5,
                                              fontFamily: isAr
                                                  ? 'Noto_Naskh_Arabic'
                                                  : null,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark, bool isAr) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        context.l10n.privacyPolicy,
        style: AppTypography.headlineSmall.copyWith(
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
          fontFamily: isAr ? 'Noto_Naskh_Arabic' : null,
        ),
      ),
      centerTitle: true,
    );
  }
}
