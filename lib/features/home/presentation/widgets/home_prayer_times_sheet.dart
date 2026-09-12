import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/home_skin.dart';

/// Shows the full [HomePrayerTimesSheet] as a modal bottom sheet.
Future<void> showHomePrayerTimesSheet(
  BuildContext context, {
  required PrayerTimesSnapshot snapshot,
  required String hijriLabel,
  HomeSkin? skin,
  DateTime Function()? now,
}) {
  final themeSkin = skin ?? HomeSkin.forBrightness(Theme.of(context).brightness);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (context) => HomePrayerTimesSheet(
      snapshot: snapshot,
      hijriLabel: hijriLabel,
      skin: themeSkin,
      now: now,
    ),
  );
}

class HomePrayerTimesSheet extends StatefulWidget {
  const HomePrayerTimesSheet({
    super.key,
    required this.snapshot,
    required this.hijriLabel,
    this.skin,
    this.now,
  });

  final PrayerTimesSnapshot snapshot;
  final String hijriLabel;
  final HomeSkin? skin;
  final DateTime Function()? now;

  @override
  State<HomePrayerTimesSheet> createState() => _HomePrayerTimesSheetState();
}

class _HomePrayerTimesSheetState extends State<HomePrayerTimesSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _weekdayName(BuildContext context, int weekday) {
    final l10n = context.l10n;
    return switch (weekday) {
      DateTime.monday => l10n.weekdayMonday,
      DateTime.tuesday => l10n.weekdayTuesday,
      DateTime.wednesday => l10n.weekdayWednesday,
      DateTime.thursday => l10n.weekdayThursday,
      DateTime.friday => l10n.weekdayFriday,
      DateTime.saturday => l10n.weekdaySaturday,
      DateTime.sunday => l10n.weekdaySunday,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final themeSkin =
        widget.skin ?? HomeSkin.forBrightness(Theme.of(context).brightness);
    final l10n = context.l10n;
    final currentTime = widget.now?.call() ?? DateTime.now();
    final weekday = _weekdayName(context, currentTime.weekday);
    final cityName = context.isArabic
        ? widget.snapshot.city.nameAr
        : widget.snapshot.city.nameEn;

    final prayers = [
      _PrayerData(
        key: 'fajr',
        name: l10n.prayerFajr,
        time: widget.snapshot.fajr,
        icon: Icons.wb_twilight_rounded,
      ),
      _PrayerData(
        key: 'sunrise',
        name: l10n.prayerSunrise,
        time: widget.snapshot.sunrise,
        icon: Icons.wb_sunny_outlined,
      ),
      _PrayerData(
        key: 'dhuhr',
        name: l10n.prayerDhuhr,
        time: widget.snapshot.dhuhr,
        icon: Icons.wb_sunny_rounded,
      ),
      _PrayerData(
        key: 'asr',
        name: l10n.prayerAsr,
        time: widget.snapshot.asr,
        icon: Icons.wb_cloudy_rounded,
      ),
      _PrayerData(
        key: 'maghrib',
        name: l10n.prayerMaghrib,
        time: widget.snapshot.maghrib,
        icon: Icons.nights_stay_outlined,
      ),
      _PrayerData(
        key: 'isha',
        name: l10n.prayerIsha,
        time: widget.snapshot.isha,
        icon: Icons.nights_stay_rounded,
      ),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: themeSkin.scaffold,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        border: Border(
          top: BorderSide(color: themeSkin.glassBorder, width: 1.5),
        ),
        boxShadow: themeSkin.shadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeSkin.glassBorder,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: themeSkin.gold.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeSkin.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.mosque_rounded,
                      color: themeSkin.gold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.homePrayerTimesSheetTitle,
                          style: AppTypography.titleMedium.copyWith(
                            color: themeSkin.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              weekday,
                              style: AppTypography.bodySmall.copyWith(
                                color: themeSkin.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.hijriLabel.isNotEmpty) ...[
                              Text(
                                '•',
                                style: AppTypography.bodySmall.copyWith(
                                  color: themeSkin.textSecondary,
                                ),
                              ),
                              Text(
                                widget.hijriLabel,
                                style: AppTypography.bodySmall.copyWith(
                                  color: themeSkin.textSecondary,
                                ),
                              ),
                            ],
                            Text(
                              '•',
                              style: AppTypography.bodySmall.copyWith(
                                color: themeSkin.textSecondary,
                              ),
                            ),
                            Text(
                              cityName,
                              style: AppTypography.bodySmall.copyWith(
                                color: themeSkin.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: themeSkin.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: AppSpacing.md),
            // Prayer rows list
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.xs,
                  AppSpacing.pagePadding,
                  AppSpacing.lg,
                ),
                itemCount: prayers.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final prayer = prayers[index];
                  final isNext = prayer.key == widget.snapshot.nextName;
                  final isPast = prayer.time != null &&
                      currentTime.isAfter(prayer.time!) &&
                      !isNext;

                  final start = (index * 0.08).clamp(0.0, 1.0);
                  final end = (start + 0.45).clamp(0.0, 1.0);
                  final animation = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(start, end, curve: Curves.easeOutCubic),
                  );

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      if (MediaQuery.disableAnimationsOf(context)) {
                        return child!;
                      }
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _PrayerCard(
                      prayer: prayer,
                      isNext: isNext,
                      isPast: isPast,
                      minutesUntil: widget.snapshot.minutesUntil,
                      skin: themeSkin,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerData {
  const _PrayerData({
    required this.key,
    required this.name,
    required this.time,
    required this.icon,
  });

  final String key;
  final String name;
  final DateTime? time;
  final IconData icon;
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.prayer,
    required this.isNext,
    required this.isPast,
    required this.minutesUntil,
    required this.skin,
  });

  final _PrayerData prayer;
  final bool isNext;
  final bool isPast;
  final int minutesUntil;
  final HomeSkin skin;

  String _formatTime(BuildContext context, DateTime? time) {
    if (time == null) return '--:--';
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = context.isArabic
        ? (time.hour >= 12 ? 'م' : 'ص')
        : (time.hour >= 12 ? 'PM' : 'AM');
    return '$hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatTime(context, prayer.time);
    final isArabic = context.isArabic;

    Color backgroundColor;
    Border? border;
    List<BoxShadow>? shadows;
    double opacity = 1.0;

    if (isNext) {
      backgroundColor = skin.gold.withValues(alpha: 0.12);
      border = Border.all(color: skin.gold, width: 1.5);
      shadows = [
        BoxShadow(
          color: skin.gold.withValues(alpha: 0.18),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (isPast) {
      backgroundColor = skin.glassFill.withValues(alpha: 0.5);
      border = Border.all(color: skin.glassBorder.withValues(alpha: 0.5));
      opacity = 0.65;
    } else {
      backgroundColor = skin.glassFill;
      border = Border.all(color: skin.glassBorder);
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: border,
          boxShadow: shadows,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isNext
                    ? skin.gold.withValues(alpha: 0.2)
                    : skin.scaffold.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                prayer.icon,
                color: isNext ? skin.gold : skin.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Row(
                children: [
                  Text(
                    prayer.name,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isNext ? skin.gold : skin.textPrimary,
                      fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  if (isNext) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: skin.gold.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                          color: skin.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: skin.gold,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$minutesUntil ${isArabic ? "د" : "min"}',
                            style: AppTypography.labelSmall.copyWith(
                              color: skin.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: AppTypography.titleSmall.copyWith(
                    color: isNext ? skin.gold : skin.textPrimary,
                    fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (isPast) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: skin.textSecondary.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
