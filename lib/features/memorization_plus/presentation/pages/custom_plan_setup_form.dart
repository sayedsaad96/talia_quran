part of 'custom_plan_setup_page.dart';

mixin _CustomPlanRangeFields on _CustomPlanSetupController {
  Widget _buildSurahRangeSelector(bool isDark, Color primary) {
    final directionForward = _startSurahId <= _endSurahId;
    final fromName = _startSurahId < _surahNames.length
        ? _surahNames[_startSurahId]
        : '${context.l10n.surah} $_startSurahId';
    final toName = _endSurahId < _surahNames.length
        ? _surahNames[_endSurahId]
        : '${context.l10n.surah} $_endSurahId';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          // "من سورة" = نقطة البداية العددية الأصغر (_startSurahId)
          // مثال جزء عم: من سورة النبأ (78) ... إلى سورة الناس (114)
          // الحفظ يسير تنازلياً: endSurahId (الناس) ← startSurahId (النبأ)
          _buildDropdownRow(
            label: context.l10n.customPlanFromSurah,
            value: _startSurahId,
            icon: TaliaIcons.firstPage,
            isDark: isDark,
            onChanged: (v) {
              setState(() {
                _setStartSurah(v);
              });
            },
          ),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          // "إلى سورة" = نقطة النهاية العددية الأكبر (_endSurahId)
          // مثال جزء عم: إلى سورة الناس (114)
          _buildDropdownRow(
            label: context.l10n.customPlanToSurah,
            value: _endSurahId,
            icon: TaliaIcons.lastPage,
            isDark: isDark,
            onChanged: (v) {
              setState(() {
                _endSurahId = v;
                _clampStartAyahForSurah();
              });
            },
          ),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          // Explicit direction hint — resolves the ascending/descending
          // ambiguity when "من" sits above "إلى" numerically (e.g. Juz Amma).
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  directionForward
                      ? TaliaIcons.progress
                      : TaliaIcons.trendingDown,
                  color: primary,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    directionForward
                        ? context.l10n.customPlanDirectionForward(
                            fromName,
                            toName,
                          )
                        : context.l10n.customPlanDirectionBackward(
                            fromName,
                            toName,
                          ),
                    style: AppTypography.bodySmall.copyWith(
                      color: context.tokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                TaliaIcons.listNumbered,
                color: context.tokens.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.customPlanFromAyah,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 118,
                child: TextFormField(
                  controller: _startAyahController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = context.digitText(
                        LocaleNumberFormatter.western(newValue.text),
                      );
                      return newValue.copyWith(
                        text: text,
                        selection: TextSelection.collapsed(offset: text.length),
                      );
                    }),
                  ],
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.tokens.textPrimary,
                  ),
                  decoration: InputDecoration(
                    helperText: context.digitText(
                      context.digitText(
                        '1-${_ayahCountForSurah(_startSurahId)}',
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(
                      LocaleNumberFormatter.western(v),
                    );
                    if (parsed != null && parsed >= 1) {
                      setState(() => _startAyah = parsed);
                    }
                  },
                  validator: (v) {
                    final parsed = int.tryParse(
                      LocaleNumberFormatter.western((v ?? '').trim()),
                    );
                    final maxAyah = _ayahCountForSurah(_startSurahId);
                    if (parsed == null || parsed < 1) {
                      return context.l10n.customPlanInvalidAyah;
                    }
                    if (parsed > maxAyah) {
                      return context.l10n.customPlanSurahAyahLimit(
                        maxAyah,
                        context.numText(maxAyah),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required int value,
    required IconData icon,
    required bool isDark,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: context.tokens.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: context.tokens.textPrimary,
          ),
        ),
        const Spacer(),
        DropdownButton<int>(
          value: value,
          underline: const SizedBox.shrink(),
          dropdownColor: context.tokens.surface,
          style: AppTypography.bodyMedium.copyWith(
            color: context.tokens.textPrimary,
          ),
          items: List.generate(
            114,
            (i) => DropdownMenuItem(
              value: i + 1,
              child: Text(
                '${i + 1}. ${(i + 1) < _surahNames.length ? _surahNames[i + 1] : '${context.l10n.surah} ${i + 1}'}',
              ),
            ),
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _buildSliderCard({
    required String title,
    required int value,
    required int min,
    required int max,
    required String suffix,
    required IconData icon,
    required Color color,
    required bool isDark,
    required ValueChanged<int> onChanged,
    int? divisions,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.tokens.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Text(
                  '$value $suffix',
                  style: AppTypography.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: divisions ?? (max - min),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }

  /// A child's plan belongs to the kids path, so choosing «طفل» leaves this
  /// adult plan screen for kids setup. An adult path in use is ended only
  /// after an explicit confirmation (same effect as "Reset path").
}
