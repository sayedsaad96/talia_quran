import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
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
  final _service = getIt<PrayerTimesService>();
  late bool _enabled;
  String? _cityId;
  late String _method;
  List<PrayerCity> _cities = const [];

  @override
  void initState() {
    super.initState();
    _enabled = _service.isEnabled;
    _cityId = _service.selectedCityId;
    _method = _service.calculationMethod;
    _service.cities().then((cities) {
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _cityId ??= cities.isEmpty ? null : cities.first.id;
      });
    });
  }

  Future<void> _setEnabled(bool value) async {
    await _service.setEnabled(value);
    setState(() => _enabled = value);
  }

  Future<void> _setCity(String? id) async {
    if (id == null) return;
    await _service.setCityId(id);
    setState(() => _cityId = id);
  }

  Future<void> _setMethod(String? method) async {
    if (method == null) return;
    await _service.setCalculationMethod(method);
    setState(() => _method = method);
  }

  String _methodLabel(BuildContext context, String method) {
    return switch (method) {
      'egyptian' => context.l10n.prayerMethodEgyptian,
      'umm_al_qura' => context.l10n.prayerMethodUmmAlQura,
      'karachi' => context.l10n.prayerMethodKarachi,
      'north_america' => context.l10n.prayerMethodNorthAmerica,
      _ => context.l10n.prayerMethodMwl,
    };
  }

  @override
  Widget build(BuildContext context) {
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
            title: Text(context.l10n.homePrayerCity),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              value: _cities.any((c) => c.id == _cityId)
                  ? _cityId
                  : (_cities.isEmpty ? null : _cities.first.id),
              items: [
                for (final city in _cities)
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
              value: _method,
              items: [
                for (final method in [
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
