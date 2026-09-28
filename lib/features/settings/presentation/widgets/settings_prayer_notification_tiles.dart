import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/adhan_preview_service.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/prayer_sound.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/notification_settings_cubit.dart';
import '../cubits/notification_settings_state.dart';

/// Self-contained prayer notification settings: master toggle, per-prayer
/// filter chips, full-adhan switch, muezzin picker, and Android exact-alarm
/// permission request.
///
/// This widget creates and owns its own [NotificationSettingsCubit] when one is
/// not already registered, so it can be embedded in any settings page without
/// requiring the notification settings page infrastructure.
class PrayerNotificationSettingsSection extends StatefulWidget {
  const PrayerNotificationSettingsSection({
    super.key,
    required this.isDark,
    this.onConfigurePrayerTimes,
  });

  final bool isDark;
  final VoidCallback? onConfigurePrayerTimes;

  @override
  State<PrayerNotificationSettingsSection> createState() =>
      _PrayerNotificationSettingsSectionState();
}

class _PrayerNotificationSettingsSectionState
    extends State<PrayerNotificationSettingsSection>
    with WidgetsBindingObserver {
  static const _prayerTimesKey =
      TaliaNotificationService.prayerNotificationsPreferenceKey;
  static const _prayerFajrKey = TaliaNotificationService.prayerFajrKey;
  static const _prayerDhuhrKey = TaliaNotificationService.prayerDhuhrKey;
  static const _prayerAsrKey = TaliaNotificationService.prayerAsrKey;
  static const _prayerMaghribKey = TaliaNotificationService.prayerMaghribKey;
  static const _prayerIshaKey = TaliaNotificationService.prayerIshaKey;
  static const _prayerAthanKey = TaliaNotificationService.prayerAthanKey;

  final AdhanPreviewService _previewService = AdhanPreviewService();
  late final NotificationSettingsCubit _cubit;
  bool _ownsCubit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (getIt.isRegistered<NotificationSettingsCubit>()) {
      _cubit = getIt<NotificationSettingsCubit>()..load();
      _ownsCubit = true;
    } else {
      final prefs = getIt.isRegistered<SharedPreferences>()
          ? getIt<SharedPreferences>()
          : null;
      final service = getIt.isRegistered<TaliaNotificationService>()
          ? getIt<TaliaNotificationService>()
          : TaliaNotificationService();
      final scheduler = getIt.isRegistered<NotificationScheduler>()
          ? getIt<NotificationScheduler>()
          : null;

      if (prefs != null) {
        _cubit = NotificationSettingsCubit(prefs, service, scheduler)..load();
        _ownsCubit = true;
      } else {
        // Fallback for isolated widget tests without prefs initialized
        SharedPreferences.getInstance().then((p) {
          _cubit = NotificationSettingsCubit(p, service, scheduler)..load();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cubit.checkPermission();
    }
  }

  String _selectedMuezzinId(NotificationSettingsState state) {
    if (state.muezzinId.isNotEmpty &&
        MuezzinCatalog.isGeneralSupported(state.muezzinId)) {
      return state.muezzinId;
    }
    final stored = _cubit.prefs.getString(
      TaliaNotificationService.prayerMuezzinKey,
    );
    final id = (stored == null || stored.isEmpty)
        ? MuezzinCatalog.defaultId
        : stored;
    return MuezzinCatalog.generalSelection(id);
  }

  String _selectedFajrMuezzinId(NotificationSettingsState state) {
    final rawGeneral = state.muezzinId.isNotEmpty
        ? state.muezzinId
        : _cubit.prefs.getString(TaliaNotificationService.prayerMuezzinKey) ??
              MuezzinCatalog.defaultId;
    final rawFajr = state.fajrMuezzinId.isNotEmpty
        ? state.fajrMuezzinId
        : _cubit.prefs.getString(
                TaliaNotificationService.prayerMuezzinFajrKey,
              ) ??
              '';
    return MuezzinCatalog.fajrSelection(
      generalMuezzinId: rawGeneral,
      fajrMuezzinId: rawFajr,
    );
  }

  Future<void> _openMuezzinPicker(
    BuildContext context,
    Color primary,
    NotificationSettingsState state,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _MuezzinPickerSheet(
        initialMuezzinId: _selectedMuezzinId(state),
        initialFajrMuezzinId: _selectedFajrMuezzinId(state),
        primary: primary,
        previewService: _previewService,
        cubit: _cubit,
      ),
    );
    // Stop preview if the sheet was dismissed mid-playback.
    await _previewService.stop();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildPrayerChip({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color primary,
  }) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: primary.withValues(alpha: 0.18),
      checkmarkColor: primary,
      labelStyle: AppTypography.labelSmall.copyWith(
        color: value ? primary : null,
        fontWeight: value ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = context.tokens.textPrimary;
    final subtextColor = context.tokens.textSecondary;
    final primary = context.tokens.accent;

    final prayerTimesService = getIt.isRegistered<PrayerTimesService>()
        ? getIt<PrayerTimesService>()
        : null;
    final prayerTimesReady =
        prayerTimesService?.isReadyForNotificationScheduling ?? false;

    return BlocConsumer<NotificationSettingsCubit, NotificationSettingsState>(
      bloc: _cubit,
      listenWhen: (previous, current) =>
          previous.feedbackRevision != current.feedbackRevision,
      listener: (context, state) {
        final message = switch (state.feedback) {
          NotificationSettingsFeedback.saveFailed =>
            context.l10n.notificationSettingsSaveFailed,
          NotificationSettingsFeedback.schedulingFailed =>
            context.l10n.notificationSettingsSchedulingFailed,
          null => null,
        };
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        return Column(
          children: [
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              secondary: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mosque_rounded, color: primary, size: 22),
              ),
              title: Text(
                context.l10n.notificationSettingsPrayerTimes,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                prayerTimesReady
                    ? context.l10n.notificationSettingsPrayerTimesSub
                    : context.l10n.notificationSettingsPrayerNeedsTimes,
                style: AppTypography.bodySmall.copyWith(
                  color: prayerTimesReady ? subtextColor : primary,
                  fontWeight: prayerTimesReady ? null : FontWeight.w600,
                ),
              ),
              value: state.prayerNotifications,
              onChanged: prayerTimesReady
                  ? (v) => _cubit.toggleReminder(
                      _prayerTimesKey,
                      v,
                      l10n: context.l10n,
                    )
                  : null,
              activeThumbColor: primary,
            ),
            if (!prayerTimesReady)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xl,
                  end: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: widget.onConfigurePrayerTimes,
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(context.l10n.notificationConfigurePrayerTimes),
                  ),
                ),
              ),
            if (state.isSystemPermissionBlocked)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: _NotificationPermissionWarning(
                  isDark: widget.isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
            if (state.prayerNotifications && prayerTimesReady)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildPrayerChip(
                      label: context.l10n.prayerFajr,
                      value: state.prayerFajr,
                      onChanged: (v) => _cubit.togglePrayer(
                        _prayerFajrKey,
                        v,
                        l10n: context.l10n,
                      ),
                      primary: primary,
                    ),
                    _buildPrayerChip(
                      label: context.l10n.prayerDhuhr,
                      value: state.prayerDhuhr,
                      onChanged: (v) => _cubit.togglePrayer(
                        _prayerDhuhrKey,
                        v,
                        l10n: context.l10n,
                      ),
                      primary: primary,
                    ),
                    _buildPrayerChip(
                      label: context.l10n.prayerAsr,
                      value: state.prayerAsr,
                      onChanged: (v) => _cubit.togglePrayer(
                        _prayerAsrKey,
                        v,
                        l10n: context.l10n,
                      ),
                      primary: primary,
                    ),
                    _buildPrayerChip(
                      label: context.l10n.prayerMaghrib,
                      value: state.prayerMaghrib,
                      onChanged: (v) => _cubit.togglePrayer(
                        _prayerMaghribKey,
                        v,
                        l10n: context.l10n,
                      ),
                      primary: primary,
                    ),
                    _buildPrayerChip(
                      label: context.l10n.prayerIsha,
                      value: state.prayerIsha,
                      onChanged: (v) => _cubit.togglePrayer(
                        _prayerIshaKey,
                        v,
                        l10n: context.l10n,
                      ),
                      primary: primary,
                    ),
                  ],
                ),
              ),
            if (state.prayerNotifications && prayerTimesReady)
              SwitchListTile(
                contentPadding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xl,
                  end: AppSpacing.md,
                ),
                title: Text(
                  context.l10n.notificationSettingsPrayerAthan,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  context.l10n.notificationSettingsPrayerAthanSub,
                  style: AppTypography.bodySmall.copyWith(color: subtextColor),
                ),
                value: state.prayerAthan,
                onChanged: (v) => _cubit.toggleReminder(
                  _prayerAthanKey,
                  v,
                  l10n: context.l10n,
                ),
                activeThumbColor: primary,
              ),
            if (state.prayerNotifications &&
                prayerTimesReady &&
                state.prayerAthan)
              _buildMuezzinTile(
                context,
                state,
                primary,
                textColor,
                subtextColor,
              ),
            if (Platform.isAndroid &&
                state.prayerNotifications &&
                prayerTimesReady)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xl,
                  end: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.notificationExactAlarmExplanation,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtextColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final grantedMessage =
                              context.l10n.notificationExactAlarmGranted;
                          final deniedMessage =
                              context.l10n.notificationExactAlarmDenied;
                          final granted = await _cubit
                              .requestExactPrayerTimePermission();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                granted ? grantedMessage : deniedMessage,
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.alarm_rounded, size: 16),
                        label: Text(
                          context.l10n.notificationExactAlarmRequest,
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMuezzinTile(
    BuildContext context,
    NotificationSettingsState state,
    Color primary,
    Color textColor,
    Color subtextColor,
  ) {
    final l10n = context.l10n;
    final muezzinId = _selectedMuezzinId(state);
    final fajrMuezzinId = _selectedFajrMuezzinId(state);
    final muezzin = MuezzinCatalog.byId(muezzinId);
    final fajrOverride = fajrMuezzinId.isNotEmpty
        ? MuezzinCatalog.byId(fajrMuezzinId)
        : null;
    final subtitle = fajrOverride == null
        ? muezzin?.name(l10n.localeName) ?? l10n.muezzinDefault
        : l10n.muezzinFajrSummary(
            muezzin?.name(l10n.localeName) ?? l10n.muezzinDefault,
            fajrOverride.name(l10n.localeName),
          );
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xl,
        end: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.graphic_eq_rounded, color: primary, size: 22),
            title: Text(
              l10n.muezzinPickerTitle,
              style: AppTypography.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(color: subtextColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: subtextColor,
              size: 22,
            ),
            onTap: () => _openMuezzinPicker(context, primary, state),
          ),
        ],
      ),
    );
  }
}

class _NotificationPermissionWarning extends StatelessWidget {
  const _NotificationPermissionWarning({
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
  });

  final bool isDark;
  final Color textColor;
  final Color subtextColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.notificationPermissionBlockedTitle,
                  style: AppTypography.labelLarge.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.notificationPrayerPermissionBlockedBody,
            style: AppTypography.bodySmall.copyWith(color: subtextColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: openAppSettings,
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: Text(context.l10n.notificationOpenSystemSettings),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet muezzin picker: radio list of the bundled adhan recordings
/// with an inline preview button per option, plus an optional Fajr-only
/// override selector.
class _MuezzinPickerSheet extends StatefulWidget {
  const _MuezzinPickerSheet({
    required this.initialMuezzinId,
    required this.initialFajrMuezzinId,
    required this.primary,
    required this.previewService,
    required this.cubit,
  });

  final String initialMuezzinId;
  final String initialFajrMuezzinId;
  final Color primary;
  final AdhanPreviewService previewService;
  final NotificationSettingsCubit cubit;

  @override
  State<_MuezzinPickerSheet> createState() => _MuezzinPickerSheetState();
}

class _MuezzinPickerSheetState extends State<_MuezzinPickerSheet> {
  late String _muezzinId = MuezzinCatalog.generalSelection(
    widget.initialMuezzinId,
  );
  late String _fajrMuezzinId = MuezzinCatalog.fajrSelection(
    generalMuezzinId: widget.initialMuezzinId,
    fajrMuezzinId: widget.initialFajrMuezzinId,
  );
  String? _previewingId;

  @override
  void dispose() {
    widget.previewService.stop();
    super.dispose();
  }

  Future<void> _togglePreview(String id) async {
    final service = widget.previewService;
    if (_previewingId == id) {
      setState(() => _previewingId = null);
      await service.stop();
      return;
    }
    setState(() => _previewingId = id);
    final started = await service.start(id);
    if (!mounted) return;
    if (!started) {
      setState(() => _previewingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtext = Theme.of(context).textTheme.bodySmall?.color;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: subtext?.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.muezzinPickerTitle,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.muezzinPickerSubtitle,
              style: AppTypography.bodySmall.copyWith(color: subtext),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    RadioGroup<String>(
                      groupValue: _muezzinId,
                      onChanged: (value) => setState(() {
                        if (value != null) _muezzinId = value;
                      }),
                      child: Column(
                        children: [
                          for (final muezzin in MuezzinCatalog.all)
                            if (MuezzinCatalog.isGeneralSupported(muezzin.id))
                              _buildRow(
                                context: context,
                                id: muezzin.id,
                                title: muezzin.name(l10n.localeName),
                                subtitle: muezzin.origin(l10n.localeName),
                                isFajrSection: false,
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        l10n.muezzinFajrSectionTitle,
                        style: AppTypography.labelLarge.copyWith(
                          color: widget.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    RadioGroup<String>(
                      groupValue: _fajrMuezzinId,
                      onChanged: (value) =>
                          setState(() => _fajrMuezzinId = value ?? ''),
                      child: Column(
                        children: [
                          _buildRow(
                            context: context,
                            id: '',
                            title: l10n.muezzinFajrSameAsGeneral,
                            subtitle: null,
                            isFajrSection: true,
                          ),
                          for (final muezzin in MuezzinCatalog.all)
                            if (muezzin.id != MuezzinCatalog.defaultId)
                              _buildRow(
                                context: context,
                                id: muezzin.id,
                                title: muezzin.name(l10n.localeName),
                                subtitle: muezzin.origin(l10n.localeName),
                                isFajrSection: true,
                                fajrOptimized: muezzin.fajrOptimized,
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.previewService.stop();
                  final cubit = widget.cubit;
                  final muezzinId = _muezzinId;
                  final fajrMuezzinId = _fajrMuezzinId;
                  Navigator.of(context).pop();
                  cubit.setMuezzinSelection(
                    muezzinId: muezzinId,
                    fajrMuezzinId: fajrMuezzinId,
                    l10n: l10n,
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: widget.primary),
                child: Text(l10n.muezzinPickerSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required String id,
    required String title,
    required String? subtitle,
    required bool isFajrSection,
    bool fajrOptimized = false,
  }) {
    final selected = isFajrSection ? _fajrMuezzinId == id : _muezzinId == id;
    final previewing = _previewingId == id;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Radio<String>(value: id, activeColor: widget.primary),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (fajrOptimized) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                context.l10n.muezzinFajrBadge,
                style: AppTypography.labelSmall.copyWith(
                  color: widget.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
      trailing: IconButton(
        icon: Icon(
          previewing ? Icons.stop_circle_rounded : Icons.play_circle_rounded,
          color: widget.primary,
        ),
        tooltip: previewing
            ? context.l10n.muezzinPreviewStop
            : context.l10n.muezzinPreviewPlay,
        onPressed: () => _togglePreview(id),
      ),
      onTap: () => setState(() {
        if (isFajrSection) {
          _fajrMuezzinId = id;
        } else {
          _muezzinId = id;
        }
      }),
    );
  }
}
