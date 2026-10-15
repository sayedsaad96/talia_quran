import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/kids_surah_house_summary_builder.dart';
import '../theme/kids_theme.dart';
import 'kids_talia_companion.dart';

/// Fixed height of one map row. A fixed extent keeps the 114-house list cheap
/// and lets the map open on the current house with plain arithmetic.
const double kKidsQuranJourneyItemExtent = 132;

/// The lazily built map of surah houses.
class KidsQuranJourneyMap extends StatefulWidget {
  const KidsQuranJourneyMap({
    super.key,
    required this.houses,
    required this.currentSurahId,
    required this.nameOf,
    required this.onHouseTap,
  });

  final List<KidsSurahHouse> houses;
  final int currentSurahId;
  final String Function(int surahId) nameOf;
  final ValueChanged<KidsSurahHouse> onHouseTap;

  @override
  State<KidsQuranJourneyMap> createState() => _KidsQuranJourneyMapState();
}

class _KidsQuranJourneyMapState extends State<KidsQuranJourneyMap> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    final index = widget.houses.indexWhere(
      (h) => h.surahId == widget.currentSurahId,
    );
    _controller = ScrollController(
      initialScrollOffset:
          (index < 0 ? 0 : index) * kKidsQuranJourneyItemExtent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final houses = widget.houses;
    return ListView.builder(
      controller: _controller,
      itemExtent: kKidsQuranJourneyItemExtent,
      itemCount: houses.length,
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemBuilder: (context, index) {
        final house = houses[index];
        final firstOfJuz = index == 0 || houses[index - 1].juz != house.juz;
        return _MapRow(
          index: index,
          isLast: index == houses.length - 1,
          showJuz: firstOfJuz,
          isCurrent: house.surahId == widget.currentSurahId,
          house: house,
          name: widget.nameOf(house.surahId),
          onTap: () => widget.onHouseTap(house),
        );
      },
    );
  }
}

class _MapRow extends StatelessWidget {
  const _MapRow({
    required this.index,
    required this.isLast,
    required this.showJuz,
    required this.isCurrent,
    required this.house,
    required this.name,
    required this.onTap,
  });

  final int index;
  final bool isLast;
  final bool showJuz;
  final bool isCurrent;
  final KidsSurahHouse house;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final alignEnd = index.isOdd;
    final alignment = alignEnd
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: KidsQuranRoadPainter(
              towardEnd: alignEnd,
              isRtl: Directionality.of(context) == TextDirection.rtl,
              isFirst: index == 0,
              isLast: isLast,
              done: house.status == KidsSurahHouseStatus.completed,
            ),
          ),
        ),
        if (showJuz)
          Positioned(
            top: 2,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Align(
              alignment: alignment,
              child: _JuzSignpost(juz: house.juz),
            ),
          ),
        Positioned(
          top: 28,
          bottom: 8,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          child: Align(
            alignment: alignment,
            child: FractionallySizedBox(
              widthFactor: 0.78,
              heightFactor: 1,
              child: KidsSurahHouseCard(
                house: house,
                name: name,
                isCurrent: isCurrent,
                onTap: onTap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _JuzSignpost extends StatelessWidget {
  const _JuzSignpost({required this.juz});

  final int juz;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: KidsTheme.goldStar,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        context.l10n.kidsQuranJourneyJuz(context.numText(juz)),
        style: AppTypography.labelMedium.copyWith(
          color: KidsTheme.inkOnParchment,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// One surah house: name, ayah count, status icon and progress bar.
class KidsSurahHouseCard extends StatelessWidget {
  const KidsSurahHouseCard({
    super.key,
    required this.house,
    required this.name,
    required this.isCurrent,
    required this.onTap,
  });

  final KidsSurahHouse house;
  final String name;
  final bool isCurrent;
  final VoidCallback onTap;

  static IconData _icon(KidsSurahHouseStatus status) => switch (status) {
    KidsSurahHouseStatus.completed => Icons.check_circle_rounded,
    KidsSurahHouseStatus.needsReview => Icons.refresh_rounded,
    KidsSurahHouseStatus.inProgress => Icons.auto_stories_rounded,
    KidsSurahHouseStatus.notStarted => Icons.radio_button_unchecked_rounded,
  };

  static Color _color(KidsSurahHouseStatus status) => switch (status) {
    KidsSurahHouseStatus.completed => KidsTheme.successGreen,
    KidsSurahHouseStatus.needsReview => KidsTheme.reviewPurple,
    KidsSurahHouseStatus.inProgress => KidsTheme.goldStar,
    KidsSurahHouseStatus.notStarted => KidsTheme.lockedGrey,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final countText = l10n.kidsQuranJourneyAyahCount(
      context.numText(house.ayahCount),
    );
    final statusColor = _color(house.status);
    final statusText = switch (house.status) {
      KidsSurahHouseStatus.completed => l10n.kidsHouseStatusCompleted,
      KidsSurahHouseStatus.needsReview => l10n.kidsHouseStatusNeedsReview,
      KidsSurahHouseStatus.inProgress => l10n.kidsHouseStatusInProgress,
      KidsSurahHouseStatus.notStarted => l10n.kidsHouseStatusNotStarted,
    };
    return Semantics(
      button: true,
      container: true,
      label: [
        name,
        countText,
        statusText,
        if (isCurrent) l10n.kidsHouseCurrentMarker,
      ].join('. '),
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: KidsTheme.cardRadius,
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                gradient: KidsTheme.parchmentGradient,
                borderRadius: KidsTheme.cardRadius,
                border: Border.all(
                  color: isCurrent
                      ? KidsTheme.goldStar
                      : KidsTheme.parchmentEdge,
                  width: isCurrent ? 3 : 1.5,
                ),
                boxShadow: KidsTheme.card25DShadow,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (isCurrent) ...[
                    Image.asset(
                      KidsTaliaPose.pointRight.asset,
                      width: 40,
                      height: 40,
                      errorBuilder: (_, _, _) => const SizedBox(width: 40),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            color: KidsTheme.inkOnParchment,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0,
                          ),
                        ),
                        Text(
                          countText,
                          style: AppTypography.bodySmall.copyWith(
                            color: KidsTheme.inkOnParchment,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: house.progress.clamp(0.0, 1.0),
                            minHeight: 6,
                            color: statusColor,
                            backgroundColor: KidsTheme.parchmentEdge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(_icon(house.status), color: statusColor, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple winding road segment: enters from the previous row's side, bends
/// through this row's side, and leaves toward the next row's side.
class KidsQuranRoadPainter extends CustomPainter {
  const KidsQuranRoadPainter({
    required this.towardEnd,
    required this.isRtl,
    required this.isFirst,
    required this.isLast,
    required this.done,
  });

  /// True when this row's house sits on the end side (right in LTR).
  final bool towardEnd;
  final bool isRtl;
  final bool isFirst;
  final bool isLast;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    final rightHere = isRtl ? !towardEnd : towardEnd;
    final here = size.width * (rightHere ? 0.7 : 0.3);
    final other = size.width * (rightHere ? 0.3 : 0.7);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = done
          ? KidsTheme.goldStar.withValues(alpha: 0.55)
          : KidsTheme.mapSurface;
    final midY = size.height / 2;
    final path = Path()..moveTo(isFirst ? here : other, isFirst ? midY : 0);
    if (!isFirst) path.quadraticBezierTo(other, midY * 0.5, here, midY);
    if (!isLast) {
      path.quadraticBezierTo(here, midY * 1.5, other, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(KidsQuranRoadPainter old) =>
      old.towardEnd != towardEnd ||
      old.isRtl != isRtl ||
      old.isFirst != isFirst ||
      old.isLast != isLast ||
      old.done != done;
}
