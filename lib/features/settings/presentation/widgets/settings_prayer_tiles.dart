import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/services/prayer_times_service.dart';
import 'settings_section.dart';

class PrayerTimesSettingsSection extends StatefulWidget {
  const PrayerTimesSettingsSection({super.key, required this.isDark});

  final bool isDark;

  @override
  State<PrayerTimesSettingsSection> createState() =>
      _PrayerTimesSettingsSectionState();
}

class _PrayerTimesSettingsSectionState
    extends State<PrayerTimesSettingsSection> {
  static const _autoValue = 'auto';

  // Resolved defensively: the settings page builds every section up front, so
  // this widget can be mounted in stripped environments (isolated widget
  // tests) where core DI is not registered. The section then renders nothing
  // instead of crashing the whole settings page — the same pattern used by
  // NotificationSettingsSection.
  final PrayerTimesService? _service = getIt.isRegistered<PrayerTimesService>()
      ? getIt<PrayerTimesService>()
      : null;
  late bool _enabled;
  String? _countryId;
  String? _cityId;
  late String _method;
  late bool _methodAuto;
  List<PrayerCountry> _countries = const [];

  @override
  void initState() {
    super.initState();
    final service = _service;
    if (service == null) return;
    _enabled = service.isEnabled;
    _cityId = service.selectedCityId;
    _method = service.calculationMethod;
    _methodAuto = !service.isMethodManual;
    service.countries().then((countries) {
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _countryId = _countryFor(_cityId)?.id;
        if (_methodAuto) _method = service.calculationMethod;
      });
    });
  }

  PrayerCountry? _countryFor(String? cityId) {
    for (final country in _countries) {
      if (country.cities.any((c) => c.id == cityId)) return country;
    }
    return null;
  }

  List<PrayerCity> _citiesOf(String? countryId) {
    for (final country in _countries) {
      if (country.id == countryId) return country.cities;
    }
    return const [];
  }

  Future<void> _refreshNotifications() async {
    if (getIt.isRegistered<NotificationScheduler>()) {
      final updated = await getIt<NotificationScheduler>()
          .refreshNotificationsForSettings(context.l10n, force: true);
      if (!updated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.notificationSettingsSchedulingFailed),
          ),
        );
      }
    }
  }

  Future<void> _setEnabled(bool value) async {
    final service = _service;
    if (service == null) return;
    await service.setEnabled(value);
    if (!mounted) return;
    setState(() => _enabled = value);
    await _refreshNotifications();
  }

  Future<void> _setCountry(String? id) async {
    if (id == null || id == _countryId) return;
    final cities = _citiesOf(id);
    if (cities.isEmpty) return;
    try {
      if (await _service?.clearCityId() != true) {
        throw StateError('Failed to clear selected prayer city');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.notificationSettingsSaveFailed)),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _countryId = id;
      _cityId = null;
    });
    await _refreshNotifications();
  }

  Future<void> _setCity(String? id) async {
    final service = _service;
    if (id == null || service == null) return;
    await service.setCityId(id);
    if (!mounted) return;
    setState(() {
      _cityId = id;
      _countryId = _countryFor(id)?.id ?? _countryId;
      if (_methodAuto) _method = service.calculationMethod;
    });
    await _refreshNotifications();
  }

  Future<void> _setMethod(String? method) async {
    final service = _service;
    if (method == null || service == null) return;
    if (method == _autoValue) {
      await service.setMethodAutomatic();
    } else {
      await service.setCalculationMethod(method);
    }
    if (!mounted) return;
    setState(() {
      _methodAuto = method == _autoValue;
      _method = service.calculationMethod;
    });
    await _refreshNotifications();
  }

  String _methodLabel(BuildContext context, String method) {
    return switch (method) {
      _autoValue => context.l10n.prayerMethodAuto,
      'egyptian' => context.l10n.prayerMethodEgyptian,
      'umm_al_qura' => context.l10n.prayerMethodUmmAlQura,
      'karachi' => context.l10n.prayerMethodKarachi,
      'north_america' => context.l10n.prayerMethodNorthAmerica,
      _ => context.l10n.prayerMethodMwl,
    };
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    if (service == null) return const SizedBox.shrink();
    final cities = _citiesOf(_countryId);
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.homePrayerTimesEnabled),
          value: _enabled,
          onChanged: _setEnabled,
        ),
        if (_enabled) ...[
          SettingsDivider(isDark: widget.isDark),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.homePrayerCountry),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              value: _countryId,
              hint: Text(context.l10n.homePrayerCountry),
              items: [
                for (final country in _countries)
                  DropdownMenuItem(
                    value: country.id,
                    child: Text(
                      context.isArabic ? country.nameAr : country.nameEn,
                    ),
                  ),
              ],
              onChanged: _setCountry,
            ),
          ),
          SettingsDivider(isDark: widget.isDark),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.homePrayerCity),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              value: cities.any((city) => city.id == _cityId) ? _cityId : null,
              hint: Text(context.l10n.prayerChooseCityAction),
              items: [
                for (final city in cities)
                  DropdownMenuItem(
                    value: city.id,
                    child: Text(context.isArabic ? city.nameAr : city.nameEn),
                  ),
              ],
              onChanged: _setCity,
            ),
          ),
          SettingsDivider(isDark: widget.isDark),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.homePrayerMethod),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              value: _methodAuto ? _autoValue : _method,
              items: [
                for (final method in [
                  _autoValue,
                  CalculationMethod.muslim_world_league.name,
                  CalculationMethod.egyptian.name,
                  CalculationMethod.umm_al_qura.name,
                  CalculationMethod.karachi.name,
                  CalculationMethod.north_america.name,
                ])
                  DropdownMenuItem(
                    value: method,
                    child: Text(_methodLabel(context, method)),
                  ),
              ],
              onChanged: _setMethod,
            ),
          ),
        ],
      ],
    );
  }
}
