import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../data/datasources/prayer_companion_preferences.dart';
import '../../domain/entities/prayer_companion.dart';
import '../../domain/repositories/prayer_companion_repository.dart';
import '../../../settings/presentation/widgets/settings_section.dart';

/// Opt-in Prayer Companion settings.
///
/// Owns only Companion preferences and local-history deletion. Existing
/// prayer-time alerts keep their own settings surface, and disabling the
/// Companion never touches prayer-time notification settings.
class PrayerCompanionSettingsSection extends StatefulWidget {
  const PrayerCompanionSettingsSection({super.key, required this.isDark});

  final bool isDark;

  @override
  State<PrayerCompanionSettingsSection> createState() =>
      _PrayerCompanionSettingsSectionState();
}

class _PrayerCompanionSettingsSectionState
    extends State<PrayerCompanionSettingsSection> {
  final _preferences = getIt<PrayerCompanionPreferences>();
  late PrayerCompanionSettings _settings;

  /// Preparation intervals offered in V1: disabled or 5/10/15 minutes.
  static const List<int> _preparationOptions = [0, 5, 10, 15];

  @override
  void initState() {
    super.initState();
    _settings = _preferences.read();
  }

  /// Every preference change is persisted before notifications are
  /// rescheduled, so the scheduler always sees the new value.
  Future<void> _apply(PrayerCompanionSettings next) async {
    await _preferences.write(next);
    if (!mounted) return;
    setState(() => _settings = _preferences.read());
    await _refreshNotifications();
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) return;
    final l10n = context.l10n;
    if (getIt.isRegistered<NotificationScheduler>()) {
      await getIt<NotificationScheduler>().refreshNotifications(
        l10n,
        force: true,
      );
    }
  }

  String _preparationLabel(BuildContext context, int minutes) {
    if (minutes == 0) return context.l10n.prayerCompanionPreparationDisabled;
    return context.l10n.prayerCompanionMinutesValue(minutes);
  }

  Future<void> _confirmClear() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.prayerCompanionClearConfirmTitle),
        content: Text(l10n.prayerCompanionClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.prayerCompanionClearCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.prayerCompanionClearConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _clearRecords();
  }

  Future<void> _clearRecords() async {
    final l10n = context.l10n;
    try {
      final ownerId = getIt<RecordOwnerProvider>().currentOwnerId;
      await getIt<PrayerCompanionRepository>().clearOwner(ownerId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.prayerCompanionCleared)));
    } catch (error, stackTrace) {
      TaliaLogger.w('Prayer companion history clear failed', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.prayerCompanionClearFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.prayerCompanionEnable),
          value: _settings.enabled,
          onChanged: (value) => _apply(_settings.copyWith(enabled: value)),
        ),
        if (_settings.enabled) ...[
          SettingsDivider(isDark: widget.isDark),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.prayerCompanionPreparation),
            subtitle: DropdownButton<int>(
              isExpanded: true,
              value: _settings.preparationMinutes,
              items: [
                for (final minutes in _preparationOptions)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(_preparationLabel(context, minutes)),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                _apply(_settings.copyWith(preparationMinutes: value));
              },
            ),
          ),
          SettingsDivider(isDark: widget.isDark),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.prayerCompanionCheckIn),
            subtitle: Text(l10n.prayerCompanionCheckInSub),
            value: _settings.checkInEnabled,
            onChanged: (value) =>
                _apply(_settings.copyWith(checkInEnabled: value)),
          ),
          SettingsDivider(isDark: widget.isDark),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.prayerCompanionFollowUp),
            subtitle: Text(l10n.prayerCompanionFollowUpSub),
            value: _settings.followUpEnabled,
            onChanged: (value) =>
                _apply(_settings.copyWith(followUpEnabled: value)),
          ),
        ],
        SettingsDivider(isDark: widget.isDark),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_outline_rounded),
          title: Text(l10n.prayerCompanionLocalOnly),
        ),
        SettingsDivider(isDark: widget.isDark),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_outline_rounded),
          title: Text(l10n.prayerCompanionClear),
          subtitle: Text(l10n.prayerCompanionClearSub),
          onTap: _confirmClear,
        ),
      ],
    );
  }
}
