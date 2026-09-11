import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/datasources/azkar_preferences_store.dart';

class FreeTasbeehSheet extends StatefulWidget {
  const FreeTasbeehSheet({
    super.key,
    required this.prefsStore,
    this.isDark = false,
  });

  final AzkarPreferencesStore prefsStore;
  final bool isDark;

  static Future<void> show(
    BuildContext context, {
    AzkarPreferencesStore? store,
    bool? isDark,
  }) async {
    final effectiveStore = store ??
        (getIt.isRegistered<AzkarPreferencesStore>()
            ? getIt<AzkarPreferencesStore>()
            : AzkarPreferencesStore());
    final effectiveIsDark =
        isDark ?? Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: FreeTasbeehSheet(
          prefsStore: effectiveStore,
          isDark: effectiveIsDark,
        ),
      ),
    );
  }

  @override
  State<FreeTasbeehSheet> createState() => _FreeTasbeehSheetState();
}

class _FreeTasbeehSheetState extends State<FreeTasbeehSheet> {
  int _counter = 0;
  late int _target;

  static const List<int> _targetOptions = [33, 100, 0];

  @override
  void initState() {
    super.initState();
    _target = widget.prefsStore.getLastTasbeehTarget();
  }

  void _onTapCounter() {
    setState(() {
      _counter++;
    });

    if (_target > 0 && _counter % _target == 0) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _selectTarget(int newTarget) {
    HapticFeedback.selectionClick();
    setState(() {
      _target = newTarget;
    });
    widget.prefsStore.setLastTasbeehTarget(newTarget);
  }

  void _resetCounter() {
    if (_counter == 0) return;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(
          'تصفير المسبحة',
          style: AppTypography.titleMedium.copyWith(
            color: widget.isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontFamily: 'Amiri',
          ),
        ),
        content: Text(
          'هل تريد إعادة تعيين العداد إلى الصفر؟',
          style: AppTypography.bodyMedium.copyWith(
            color: widget.isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تصفير'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        HapticFeedback.selectionClick();
        setState(() => _counter = 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final hintColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final progress = _target > 0 ? (_counter % _target) / _target : 0.0;
    final rounds = _target > 0 ? _counter ~/ _target : 0;

    return Material(
      color: surfaceColor,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: (widget.isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint)
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Reset Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const ValueKey('free-tasbeeh-reset-button'),
                    tooltip: 'تصفير العداد',
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: hintColor,
                      size: 22,
                    ),
                    onPressed: _resetCounter,
                  ),
                  Text(
                    'مسبحة حرة',
                    style: AppTypography.titleLarge.copyWith(
                      color: textColor,
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 48), // Balances leading action
                ],
              ),
              const SizedBox(height: 12),

              // Target Selector Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _targetOptions.map((opt) {
                  final isSelected = _target == opt;
                  final label = opt == 0 ? 'مفتوح' : '$opt';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (_) => _selectTarget(opt),
                      selectedColor: AppColors.primary,
                      backgroundColor: widget.isDark
                          ? AppColors.darkCard
                          : AppColors.lightCard,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : (widget.isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider),
                      ),
                      labelStyle: AppTypography.labelMedium.copyWith(
                        color: isSelected ? Colors.white : hintColor,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Interactive Large Counter Button
              Semantics(
                button: true,
                label: 'انقر للتسبيح، العداد الحالي $_counter',
                child: GestureDetector(
                  key: const ValueKey('free-tasbeeh-tap-area'),
                  onTap: _onTapCounter,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Arc if target set
                      if (_target > 0)
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: progress == 0.0 && _counter > 0 ? 1.0 : progress,
                            strokeWidth: 8,
                            backgroundColor: widget.isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.gold,
                            ),
                          ),
                        ),

                      // Circle Button
                      Container(
                        width: 176,
                        height: 176,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: widget.isDark
                                ? [AppColors.primary, AppColors.primaryDark]
                                : [AppColors.primaryLight, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_counter',
                              key: const ValueKey('free-tasbeeh-count-text'),
                              style: AppTypography.displayLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            if (_target > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                'الهدف: $_target' +
                                    (rounds > 0 ? ' (دورة $rounds)' : ''),
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'انقر في أي مكان في الدائرة للتسبيح',
                style: AppTypography.bodySmall.copyWith(
                  color: hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
