part of '../pages/progress_page.dart';

class _CertificatesSection extends StatefulWidget {
  const _CertificatesSection({required this.isDark, required this.isKids});
  final bool isDark;
  final bool isKids;

  @override
  State<_CertificatesSection> createState() => _CertificatesSectionState();
}

class _CertificatesSectionState extends State<_CertificatesSection> {
  List<CertificateAward> _certificates = [];
  StreamSubscription<ProgressChangedReason>? _progressChangesSub;

  @override
  void initState() {
    super.initState();
    // Certificates are read synchronously from preferences, so load before
    // the first frame instead of flashing a spinner.
    _loadCertificates();
    _progressChangesSub = getIt<ProgressEventsBus>().changes.listen((reason) {
      if (!mounted) return;
      if (reason == ProgressChangedReason.certificate ||
          reason == ProgressChangedReason.cloudPull) {
        setState(_loadCertificates);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _CertificatesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isKids != widget.isKids) _loadCertificates();
  }

  @override
  void dispose() {
    unawaited(_progressChangesSub?.cancel());
    super.dispose();
  }

  void _loadCertificates() {
    final service = getIt<AchievementService>();
    final certs = service.getEarnedCertificates(isKids: widget.isKids)
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    if (service.hasNewCertificate(isKids: widget.isKids)) {
      service.markCertificatesSeen(isKids: widget.isKids);
    }
    _certificates = certs;
  }

  @override
  Widget build(BuildContext context) {
    if (_certificates.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: context.l10n.myCertificates,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.tokens.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: context.tokens.divider),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 48,
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.earnCertificatesHint,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.myCertificates,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          // Grows with the text scale so titles and dates never clip.
          height: MediaQuery.textScalerOf(context).scale(180),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _certificates.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final cert = _certificates[index];
              return SizedBox(
                width: 240,
                child: _CertificateCard(cert: cert, isDark: widget.isDark),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.cert, required this.isDark});
  final CertificateAward cert;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isJuz = cert.type == CertificateType.juz;
    final color = isJuz ? AppColors.gold : AppColors.primary;
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: isDark ? 0.2 : 0.1),
        color.withValues(alpha: 0.05),
      ],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: () {
        context.push(
          AppRoutes.certificate,
          extra: {
            'award': cert,
            'userName': _profileDisplayName(context) ?? context.l10n.taliaUser,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isJuz
                    ? Icons.workspace_premium_rounded
                    : Icons.verified_rounded,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.localizedCertificateTitle(cert),
              textAlign: TextAlign.center,
              style: AppTypography.labelMedium.copyWith(
                color: context.tokens.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              MaterialLocalizations.of(
                context,
              ).formatMediumDate(cert.earnedAt.toLocal()),
              style: AppTypography.labelSmall.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
