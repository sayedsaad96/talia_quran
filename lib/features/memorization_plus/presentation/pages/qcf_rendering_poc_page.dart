import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum RenderingDisplayMode { singleVerse, multipleVerses, lastVerse, fullPage }

enum RenderingStatusState { supported, limited, unsupported }

@immutable
class RenderingSample {
  const RenderingSample({
    required this.id,
    required this.surahNumber,
    required this.startAyah,
    required this.endAyah,
    required this.displayMode,
    this.pageNumber,
  });

  final String id;
  final int surahNumber;
  final int startAyah;
  final int endAyah;
  final int? pageNumber;
  final RenderingDisplayMode displayMode;
}

@immutable
class RenderingStatus {
  const RenderingStatus({
    required this.sampleId,
    required this.state,
    required this.message,
  });

  final String sampleId;
  final RenderingStatusState state;
  final String message;
}

class QcfRenderingPocPage extends StatefulWidget {
  const QcfRenderingPocPage({super.key});

  @override
  State<QcfRenderingPocPage> createState() => _QcfRenderingPocPageState();
}

class _QcfRenderingPocPageState extends State<QcfRenderingPocPage> {
  late final PageController _pageController;

  static const _samples = <RenderingSample>[
    RenderingSample(
      id: 'baqarah-255',
      surahNumber: 2,
      startAyah: 255,
      endAyah: 255,
      displayMode: RenderingDisplayMode.singleVerse,
    ),
    RenderingSample(
      id: 'fatihah-1-7',
      surahNumber: 1,
      startAyah: 1,
      endAyah: 7,
      displayMode: RenderingDisplayMode.multipleVerses,
    ),
    RenderingSample(
      id: 'ikhlas-1-4',
      surahNumber: 112,
      startAyah: 1,
      endAyah: 4,
      displayMode: RenderingDisplayMode.multipleVerses,
    ),
    RenderingSample(
      id: 'ash-sharh-8',
      surahNumber: 94,
      startAyah: 8,
      endAyah: 8,
      displayMode: RenderingDisplayMode.lastVerse,
    ),
    RenderingSample(
      id: 'mushaf-page-1',
      surahNumber: 1,
      startAyah: 1,
      endAyah: 7,
      pageNumber: 1,
      displayMode: RenderingDisplayMode.fullPage,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(context.l10n.qcfPocTitle),
        leading: IconButton(
          tooltip: context.l10n.goBack,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          children: [
            _NoticePanel(
              messages: [
                context.l10n.qcfPocIntro,
                context.l10n.qcfPocNoProduction,
                context.l10n.qcfPocVisualOnly,
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SampleSection(
              title: context.l10n.qcfPocSingleVerse,
              sample: _samples[0],
              status: RenderingStatus(
                sampleId: _samples[0].id,
                state: RenderingStatusState.supported,
                message: context.l10n.qcfPocVerseSupported,
              ),
              child: _VersePreview(sample: _samples[0]),
            ),
            _SampleSection(
              title: context.l10n.qcfPocMultipleVerses,
              sample: _samples[1],
              status: RenderingStatus(
                sampleId: _samples[1].id,
                state: RenderingStatusState.supported,
                message: context.l10n.qcfPocMultiVerseSupported,
              ),
              child: _VersePreview(sample: _samples[1]),
            ),
            _SampleSection(
              title: context.l10n.qcfPocMultipleVerses,
              sample: _samples[2],
              status: RenderingStatus(
                sampleId: _samples[2].id,
                state: RenderingStatusState.supported,
                message: context.l10n.qcfPocMultiVerseSupported,
              ),
              child: _VersePreview(sample: _samples[2]),
            ),
            _SampleSection(
              title: context.l10n.qcfPocLastVerse,
              sample: _samples[3],
              status: RenderingStatus(
                sampleId: _samples[3].id,
                state: RenderingStatusState.supported,
                message: context.l10n.qcfPocVerseSupported,
              ),
              child: _VersePreview(sample: _samples[3]),
            ),
            _SampleSection(
              title: context.l10n.qcfPocFullPage,
              sample: _samples[4],
              status: RenderingStatus(
                sampleId: _samples[4].id,
                state: RenderingStatusState.supported,
                message: context.l10n.qcfPocFullPageSupported,
              ),
              child: _FullPagePreview(controller: _pageController),
            ),
            _FindingsPanel(
              statuses: [
                RenderingStatus(
                  sampleId: _samples[0].id,
                  state: RenderingStatusState.supported,
                  message: context.l10n.qcfPocVerseSupported,
                ),
                RenderingStatus(
                  sampleId: _samples[1].id,
                  state: RenderingStatusState.supported,
                  message: context.l10n.qcfPocMultiVerseSupported,
                ),
                RenderingStatus(
                  sampleId: _samples[2].id,
                  state: RenderingStatusState.supported,
                  message: context.l10n.qcfPocMultiVerseSupported,
                ),
                RenderingStatus(
                  sampleId: _samples[3].id,
                  state: RenderingStatusState.supported,
                  message: context.l10n.qcfPocVerseSupported,
                ),
                RenderingStatus(
                  sampleId: _samples[4].id,
                  state: RenderingStatusState.supported,
                  message: context.l10n.qcfPocFullPageSupported,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticePanel extends StatelessWidget {
  const _NoticePanel({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final surface = context.isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final border = context.isDark
        ? AppColors.darkDivider
        : AppColors.lightDivider;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final message in messages) ...[
              Text(message, style: AppTypography.bodyMedium),
              if (message != messages.last)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _SampleSection extends StatelessWidget {
  const _SampleSection({
    required this.title,
    required this.sample,
    required this.status,
    required this.child,
  });

  final String title;
  final RenderingSample sample;
  final RenderingStatus status;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = context.isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final border = context.isDark
        ? AppColors.darkDivider
        : AppColors.lightDivider;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$title · ${_sampleLabel(context, sample)}',
                    style: AppTypography.titleLarge,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
            const SizedBox(height: AppSpacing.md),
            Text(
              '${context.l10n.qcfPocStatus}: ${status.message}',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _VersePreview extends StatelessWidget {
  const _VersePreview({required this.sample});

  final RenderingSample sample;

  @override
  Widget build(BuildContext context) {
    final pageNumber = qcf.getPageNumber(sample.surahNumber, sample.startAyah);
    final textColor = context.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(
          children: [
            for (var ayah = sample.startAyah; ayah <= sample.endAyah; ayah++)
              TextSpan(
                text:
                    '${qcf.getVerse(sample.surahNumber, ayah)} ${qcf.getVerseEndSymbol(ayah)} ',
              ),
          ],
        ),
        textAlign: TextAlign.center,
        style: qcf.QuranTextStyles.qcfStyle(
          pageNumber: pageNumber,
          fontSize: 23,
          color: textColor,
        ).copyWith(height: 2.0),
      ),
    );
  }
}

class _FullPagePreview extends StatelessWidget {
  const _FullPagePreview({required this.controller});

  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final bg = context.isDark
        ? AppColors.parchmentDark
        : AppColors.parchmentLight;

    return SizedBox(
      height: 420,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: qcf.QuranPageView(
          pageController: controller,
          highlights: const [],
          isDarkMode: context.isDark,
          isTajweed: false,
          pageBackgroundColor: bg,
          topBar: const SizedBox.shrink(),
          bottomBar: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _FindingsPanel extends StatelessWidget {
  const _FindingsPanel({required this.statuses});

  final List<RenderingStatus> statuses;

  @override
  Widget build(BuildContext context) {
    final issues = statuses
        .where((status) => status.state != RenderingStatusState.supported)
        .toList();
    final message = issues.isEmpty
        ? context.l10n.qcfPocNoLimitations
        : issues.map((status) => status.message).join('\n');

    return _NoticePanel(
      messages: [
        context.l10n.qcfPocFindings,
        message,
        context.l10n.qcfPocLimitationInstruction,
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RenderingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status.state) {
      RenderingStatusState.supported => (
        context.l10n.qcfPocSupported,
        AppColors.success,
      ),
      RenderingStatusState.limited => (
        context.l10n.qcfPocLimited,
        AppColors.warning,
      ),
      RenderingStatusState.unsupported => (
        context.l10n.qcfPocUnsupported,
        AppColors.error,
      ),
    };

    return Semantics(
      label: '${context.l10n.qcfPocStatus}: $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

String _sampleLabel(BuildContext context, RenderingSample sample) {
  return switch (sample.id) {
    'baqarah-255' => context.l10n.qcfPocAlBaqarah255,
    'fatihah-1-7' => context.l10n.qcfPocAlFatihah,
    'ikhlas-1-4' => context.l10n.qcfPocAlIkhlas,
    'ash-sharh-8' => context.l10n.qcfPocAshSharh8,
    'mushaf-page-1' => context.l10n.qcfPocFullPageSample,
    _ => sample.id,
  };
}
