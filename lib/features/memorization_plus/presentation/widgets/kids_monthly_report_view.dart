import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/kids_monthly_report.dart';

/// The printable monthly report. Fixed light colors so the exported image and
/// PDF look the same in light and dark themes. It only reads [report] and the
/// optional guardian [note]; nothing here changes progress.
class KidsMonthlyReportView extends StatelessWidget {
  const KidsMonthlyReportView({
    super.key,
    required this.report,
    this.note = '',
    this.childName,
    this.historyComplete = true,
  });

  final KidsMonthlyReport report;

  /// False when the logs behind [report] may be partial (a linked child's
  /// capped remote history). The numbers then carry a notice and the
  /// completed-surahs section, which needs the full history, is hidden.
  final bool historyComplete;

  /// Free guardian text, shown only when not blank. Never stored.
  final String note;
  final String? childName;

  static const Color _ink = Colors.black87;
  static const Color _muted = Colors.black54;
  static const Color _paper = Colors.white;
  static const Color _line = Colors.black26;

  String _date(BuildContext context, DateTime value) {
    final locale = Localizations.localeOf(context).toString();
    return context.digitText(DateFormat.yMMMd(locale).format(value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trimmed = note.trim();
    final name = childName?.trim();
    return Container(
      color: _paper,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: DefaultTextStyle(
        style: AppTypography.bodyMedium.copyWith(color: _ink),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.monthlyReportTitle,
              style: AppTypography.titleLarge.copyWith(
                color: _ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (name != null && name.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                name,
                style: AppTypography.titleMedium.copyWith(color: _ink),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.monthlyReportPeriod(
                _date(context, report.periodStart),
                _date(context, report.periodEnd),
              ),
              style: AppTypography.bodySmall.copyWith(color: _muted),
            ),
            const Divider(color: _line, height: AppSpacing.lg * 2),
            if (report.isEmpty)
              Text(
                l10n.monthlyReportEmpty,
                key: const ValueKey('monthly-report-empty'),
              )
            else ...[
              _fact(
                l10n.monthlyReportSessions(
                  report.sessions,
                  context.numText(report.sessions),
                ),
              ),
              _fact(
                l10n.monthlyReportActiveDays(
                  report.activeDays,
                  context.numText(report.activeDays),
                ),
              ),
              _fact(
                l10n.monthlyReportNewAyahs(
                  report.newAyahs,
                  context.numText(report.newAyahs),
                ),
              ),
              _fact(
                l10n.monthlyReportReviews(
                  report.reviews,
                  context.numText(report.reviews),
                ),
              ),
              if (!historyComplete) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.monthlyReportIncompleteHistory,
                  key: const ValueKey('monthly-report-incomplete'),
                  style: AppTypography.bodySmall.copyWith(color: _muted),
                ),
              ],
              if (historyComplete && report.completedSurahIds.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _heading(l10n.monthlyReportCompleted),
                for (final id in report.completedSurahIds)
                  _fact(context.localizedSurahName(id)),
              ],
              if (report.needsSupport.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _heading(l10n.monthlyReportNeedsSupport),
                for (final a in report.needsSupport)
                  _fact(
                    l10n.monthlyReportAyahRef(
                      context.localizedSurahName(a.surahId),
                      context.numText(a.ayahNumber),
                    ),
                  ),
              ],
              if (trimmed.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _heading(l10n.monthlyReportNote),
                Container(
                  key: const ValueKey('monthly-report-note-text'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: _line),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(trimmed),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Text(
      text,
      style: AppTypography.titleSmall.copyWith(
        color: _ink,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static Widget _fact(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Text(text),
  );
}
