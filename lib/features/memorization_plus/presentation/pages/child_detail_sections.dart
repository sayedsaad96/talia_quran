part of 'child_detail_page.dart';

// ─── Header card ──────────────────────────────────────────────────────────────

class _ChildHeaderCard extends StatelessWidget {
  const _ChildHeaderCard({required this.child});
  final FamilyChildEntry child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1A6B38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              child.avatarEmoji ?? (child.isLocal ? '👨‍👧' : '🧒'),
              style: AppTypography.displayMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.shownName(context.l10n),
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (child.childAge case final age?)
                  Text(
                    context.l10n.childAgeYears(
                      age,
                      LocaleNumberFormatter.format(
                        (age).toString(),
                        context.l10n.localeName,
                      ),
                    ),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                const SizedBox(height: 4),
                if (child.isLocal)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      context.l10n.familyDashboardLocalBadge,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Today card ───────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.child});
  final FamilyChildEntry child;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: context.l10n.parentDashboardTodaySummary,
      child: child.isActiveToday
          ? Text(
              context.l10n.childDetailTodayActivity(
                LocaleNumberFormatter.format(
                  (child.todaySessions).toString(),
                  context.l10n.localeName,
                ),
                LocaleNumberFormatter.format(
                  (child.todayPoints).toString(),
                  context.l10n.localeName,
                ),
              ),
              style: AppTypography.bodyMedium,
            )
          : Text(
              context.l10n.childDetailNoActivity,
              style: AppTypography.bodyMedium.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
    );
  }
}

// ─── Metrics row ──────────────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.child});
  final FamilyChildEntry child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricChip(
            icon: '⭐',
            label: 'Lv.${context.numText(child.currentLevel)}',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricChip(
            icon: '🌟',
            label: context.numText(child.starsEarned),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricChip(
            icon: '🔥',
            label: context.numText(child.currentStreak),
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Text(icon, style: AppTypography.headlineMedium),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}

class _LearningSupportCard extends StatelessWidget {
  const _LearningSupportCard({required this.dashboard});

  final ParentDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final averageMinutes = (dashboard.averageSessionDurationSeconds / 60)
        .ceil();
    return _Panel(
      title: context.l10n.childDetailMemorizationProgress,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _SupportMetric(
            icon: TaliaIcons.calendar,
            label: context.l10n.parentCommitmentDays(
              LocaleNumberFormatter.format(
                (dashboard.commitmentDays).toString(),
                context.l10n.localeName,
              ),
            ),
          ),
          _SupportMetric(
            icon: TaliaIcons.replay,
            label: context.l10n.parentDueReviews(
              LocaleNumberFormatter.format(
                (dashboard.dueReviewCount).toString(),
                context.l10n.localeName,
              ),
            ),
          ),
          _SupportMetric(
            icon: TaliaIcons.dua,
            label: context.l10n.parentNeedsSupport(
              LocaleNumberFormatter.format(
                (dashboard.ayahsNeedingSupport).toString(),
                context.l10n.localeName,
              ),
            ),
          ),
          _SupportMetric(
            icon: TaliaIcons.timer,
            label: context.l10n.parentAverageDuration(
              LocaleNumberFormatter.format(
                (averageMinutes).toString(),
                context.l10n.localeName,
              ),
            ),
          ),
          _SupportMetric(
            icon: TaliaIcons.idea,
            label: context.l10n.parentHintUses(
              LocaleNumberFormatter.format(
                (dashboard.totalHintUses).toString(),
                context.l10n.localeName,
              ),
            ),
          ),
          // K35: a number needs a next step the parent can take.
          if (dashboard.ayahsNeedingSupport > 0) const ParentSupportTip(),
        ],
      ),
    );
  }
}

class _SupportMetric extends StatelessWidget {
  const _SupportMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide.none,
    );
  }
}

// ─── Memorization progress card ───────────────────────────────────────────────

class _MemorizationProgressCard extends StatelessWidget {
  const _MemorizationProgressCard({required this.production});
  final RemoteChildProductionSummary production;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: context.l10n.childDetailMemorizationProgress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${context.numText(production.totalMemorizedAyahs)}/${context.numText(production.totalAyahsTracked)} ${context.l10n.ayahs}',
                style: AppTypography.bodyMedium,
              ),
              Text(
                '${context.numText(production.completionPercent.round())}%',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: (production.completionPercent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          if (production.reviewsOverdue > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.parentDashboardReviewsSummary(
                LocaleNumberFormatter.format(
                  (production.reviewsCompleted).toString(),
                  context.l10n.localeName,
                ),
                LocaleNumberFormatter.format(
                  (production.reviewsOverdue).toString(),
                  context.l10n.localeName,
                ),
              ),
              style: AppTypography.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Recent sessions card ─────────────────────────────────────────────────────

class _RecentSessionsCard extends StatelessWidget {
  const _RecentSessionsCard({required this.logs});
  final List<KidsSessionLog> logs;

  @override
  Widget build(BuildContext context) {
    final recent = logs.take(5).toList();
    return _Panel(
      title: context.l10n.childDetailRecentSessions,
      child: recent.isEmpty
          ? Text(
              context.l10n.parentDashboardNoSessionsYet,
              style: AppTypography.bodyMedium,
            )
          : Column(
              children: recent.map((log) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        TaliaIcons.checkCircle,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          context.l10n.parentDashboardSessionSummary(
                            LocaleNumberFormatter.format(
                              (log.surahId).toString(),
                              context.l10n.localeName,
                            ),
                            LocaleNumberFormatter.format(
                              (log.ayahNumber).toString(),
                              context.l10n.localeName,
                            ),
                            LocaleNumberFormatter.format(
                              (log.repeatsCompleted).toString(),
                              context.l10n.localeName,
                            ),
                            LocaleNumberFormatter.format(
                              (log.pointsEarned).toString(),
                              context.l10n.localeName,
                            ),
                          ),
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ─── Shared panel widget ──────────────────────────────────────────────────────

class _DetailsLoading extends StatelessWidget {
  const _DetailsLoading({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LinearProgressIndicator(),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.familyChildDetailsLoading,
          style: AppTypography.bodySmall,
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// The child's kids progress: read on this device for a local child, or from
/// the family dashboard for a linked child on another device.
class _ChildProgressSection extends StatefulWidget {
  const _ChildProgressSection({required this.child});

  final FamilyChildEntry child;

  @override
  State<_ChildProgressSection> createState() => _ChildProgressSectionState();
}

class _ChildProgressSectionState extends State<_ChildProgressSection> {
  Future<KidsProgressSnapshot?>? _local;

  @override
  void initState() {
    super.initState();
    if (widget.child.isLocal) _local = _loadLocal();
  }

  Future<KidsProgressSnapshot?> _loadLocal() async {
    if (!getIt.isRegistered<KidsProgressSnapshotLoader>()) return null;
    try {
      return await getIt<KidsProgressSnapshotLoader>().load();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = widget.child.shownName(l10n);
    final unavailable = Text(
      l10n.childDetailProgressUnavailable,
      style: AppTypography.bodySmall.copyWith(
        color: context.tokens.textSecondary,
      ),
    );
    final summary = widget.child.remoteSummary;
    if (!widget.child.isLocal) {
      if (summary == null) return unavailable;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (summary.activity == null) ...[
            unavailable,
            const SizedBox(height: AppSpacing.sm),
          ],
          ChildProgressPanel(
            snapshot: remoteKidsProgressSnapshot(summary, now: DateTime.now()),
            childName: name,
          ),
        ],
      );
    }
    return FutureBuilder<KidsProgressSnapshot?>(
      future: _local,
      builder: (context, result) {
        if (result.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final snapshot = result.data;
        if (snapshot == null) return unavailable;
        return ChildProgressPanel(snapshot: snapshot, childName: name);
      },
    );
  }
}
