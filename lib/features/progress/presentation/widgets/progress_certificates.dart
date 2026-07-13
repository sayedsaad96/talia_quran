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
  bool _isLoading = true;
  StreamSubscription<ProgressChangedReason>? _progressChangesSub;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
    _progressChangesSub = getIt<ProgressEventsBus>().changes.listen((reason) {
      if (reason == ProgressChangedReason.certificate && mounted) {
        unawaited(_loadCertificates());
      }
    });
  }

  @override
  void dispose() {
    unawaited(_progressChangesSub?.cancel());
    super.dispose();
  }

  Future<void> _loadCertificates() async {
    final service = getIt<AchievementService>();
    final certs = service.getEarnedCertificates(isKids: widget.isKids);
    if (service.hasNewCertificate(isKids: widget.isKids)) {
      service.markCertificatesSeen(isKids: widget.isKids);
    }
    if (mounted) {
      setState(() {
        _certificates = certs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: context.l10n.myCertificates,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          const Center(child: LoadingWidget()),
        ],
      );
    }

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
              color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: widget.isDark
                    ? AppColors.darkDivider
                    : AppColors.lightDivider,
              ),
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
                      color: widget.isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: IntrinsicHeight(
            child: Row(
              children: List.generate(_certificates.length, (index) {
                final cert = _certificates[index];
                return Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: index < _certificates.length - 1 ? AppSpacing.md : 0,
                  ),
                  child: SizedBox(
                    width: 240,
                    child: _CertificateCard(cert: cert, isDark: widget.isDark),
                  ),
                );
              }),
            ),
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

    return GestureDetector(
      onTap: () {
        context.push(
          '/certificate',
          extra: {
            'award': cert,
            'userName': context.read<ProfileCubit>().state is ProfileLoaded
                ? (context.read<ProfileCubit>().state as ProfileLoaded)
                      .profile
                      .displayName
                : context.l10n.taliaUser,
          },
        );
      },
      child: Container(
        width: 140,
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
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${cert.earnedAt.day}/${cert.earnedAt.month}/${cert.earnedAt.year}',
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
