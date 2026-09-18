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

  final _service = getIt<PrayerTimesService>();
  late bool _enabled;
  String? _countryId;
  String? _cityId;
  late String _method;
  late bool _methodAuto;
  List<PrayerCountry> _countries = const [];

  @override
  void initState() {
    super.initState();
    _enabled = _service.isEnabled;
    _cityId = _service.selectedCityId;
    _method = _service.calculationMethod;
    _methodAuto = !_service.isMethodManual;
    _service.countries().then((countries) {
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _countryId =
            _countryFor(_cityId)?.id ??
            (countries.isEmpty ? null : countries.first.id);
        _cityId ??= _citiesOf(_countryId).isEmpty
            ? null
            : _citiesOf(_countryId).first.id;
        if (_methodAuto) _method = _service.calculationMethod;
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
      await getIt<NotificationScheduler>().refreshNotifications(
        context.l10n,
        force: true,
      );
    }
  }

  Future<void> _setEnabled(bool value) async {
    await _service.setEnabled(value);
    // A visible default in the dropdowns is not a confirmed location. Persist
    // the currently chosen location and method as soon as prayer times are
    // enabled, so reminder scheduling never falls back to Makkah implicitly.
    if (value && _cityId != null) {
      await _service.setCityId(_cityId!);
      if (!_methodAuto) await _service.setCalculationMethod(_method);
      _method = _service.calculationMethod;
    }
    if (!mounted) return;
    setState(() => _enabled = value);
    await _refreshNotifications();
  }

  Future<void> _setCountry(String? id) async {
    if (id == null) return;
    final cities = _citiesOf(id);
    if (cities.isEmpty) return;
    setState(() => _countryId = id);
    await _setCity(cities.first.id);
  }

  Future<void> _setCity(String? id) async {
    if (id == null) return;
    await _service.setCityId(id);
    if (!mounted) return;
    setState(() {
      _cityId = id;
      _countryId = _countryFor(id)?.id ?? _countryId;
      if (_methodAuto) _method = _service.calculationMethod;
    });
    await _refreshNotifications();
  }

  Future<void> _setMethod(String? method) async {
    if (method == null) return;
    if (method == _autoValue) {
      await _service.setMethodAutomatic();
    } else {
      await _service.setCalculationMethod(method);
    }
    if (!mounted) return;
    setState(() {
      _methodAuto = method == _autoValue;
      _method = _service.calculationMethod;
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
              value: _countries.any((c) => c.id == _countryId)
                  ? _countryId
                  : (_countries.isEmpty ? null : _countries.first.id),
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
              value: cities.any((c) => c.id == _cityId)
                  ? _cityId
                  : (cities.isEmpty ? null : cities.first.id),
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
