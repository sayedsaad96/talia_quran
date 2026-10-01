import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/services/prayer_times_service.dart';
import 'settings_section.dart';

class PrayerTimesSettingsSection extends StatefulWidget {
  const PrayerTimesSettingsSection({
    super.key,
    required this.isDark,
    this.onChanged,
  });

  final bool isDark;

  /// Called after the location, method or madhab changes, so sibling
  /// sections that depend on prayer readiness can rebuild.
  final VoidCallback? onChanged;

  /// IANA zone of the device, used for a custom location. Replaceable in
  /// tests, where the platform plugin is unavailable.
  @visibleForTesting
  static Future<String> Function() deviceTimeZone = () async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

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
  late String? _madhab;
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  String? _deviceZone;
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
    _madhab = service.isMadhabManual
        ? service.manualMadhab
        : null;
    _fillCustomFields();
    service.countries().then((countries) {
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _countryId = _cityId == PrayerTimesService.customCityId
            ? PrayerTimesService.customCityId
            : _countryFor(_cityId)?.id;
        if (_methodAuto) _method = service.calculationMethod;
      });
    });
    PrayerTimesSettingsSection.deviceTimeZone()
        .then((zone) {
          if (mounted) setState(() => _deviceZone = zone);
        })
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _fillCustomFields() {
    final custom = _service?.customCity;
    if (custom == null) return;
    _latitudeController.text = custom.latitude.toString();
    _longitudeController.text = custom.longitude.toString();
  }

  /// Accepts Western or Eastern Arabic digits and either decimal mark.
  static double? _parseCoordinate(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.trim().runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.write(rune - 0x0660);
      } else if (rune == 0x066B || rune == 0x060C || rune == 0x2C) {
        buffer.write('.');
      } else if (rune == 0x2212) {
        buffer.write('-');
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return double.tryParse(buffer.toString());
  }

  Future<void> _saveCustomLocation() async {
    final service = _service;
    if (service == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final latitude = _parseCoordinate(_latitudeController.text);
    final longitude = _parseCoordinate(_longitudeController.text);
    var zone = _deviceZone;
    if (zone == null) {
      try {
        zone = await PrayerTimesSettingsSection.deviceTimeZone();
      } catch (_) {
        zone = null;
      }
    }
    if (zone == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.prayerCustomTimeZoneUnavailable)),
      );
      return;
    }
    final saved =
        latitude != null &&
        longitude != null &&
        await service.setCustomLocation(
          latitude: latitude,
          longitude: longitude,
          timeZone: zone,
        );
    if (!mounted) return;
    if (!saved) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.prayerCustomInvalid)));
      return;
    }
    setState(() {
      _cityId = PrayerTimesService.customCityId;
      if (_methodAuto) _method = service.calculationMethod;
    });
    messenger.showSnackBar(SnackBar(content: Text(l10n.prayerCustomSaved)));
    widget.onChanged?.call();
    await _refreshNotifications();
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
    widget.onChanged?.call();
    await _refreshNotifications();
  }

  Future<void> _setCountry(String? id) async {
    if (id == null || id == _countryId) return;
    final isCustom = id == PrayerTimesService.customCityId;
    if (isCustom) _fillCustomFields();
    final cities = _citiesOf(id);
    if (cities.isEmpty && !isCustom) return;
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
    widget.onChanged?.call();
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
    widget.onChanged?.call();
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
    widget.onChanged?.call();
    await _refreshNotifications();
  }

  Future<void> _setMadhab(String? madhab) async {
    final service = _service;
    if (madhab == null || service == null) return;
    if (madhab == _autoValue) {
      await service.setMadhabAutomatic();
    } else {
      await service.setMadhab(madhab);
    }
    if (!mounted) return;
    setState(() => _madhab = madhab == _autoValue ? null : madhab);
    widget.onChanged?.call();
    await _refreshNotifications();
  }

  /// Every `adhan` method with fixed parameters. `tehran` (Ja'fari) and
  /// `other` (no angles) are deliberately not offered.
  static final _methods = [
    CalculationMethod.muslim_world_league,
    CalculationMethod.egyptian,
    CalculationMethod.umm_al_qura,
    CalculationMethod.karachi,
    CalculationMethod.north_america,
    CalculationMethod.dubai,
    CalculationMethod.kuwait,
    CalculationMethod.qatar,
    CalculationMethod.singapore,
    CalculationMethod.turkey,
    CalculationMethod.moon_sighting_committee,
  ].map((method) => method.name).toList();

  String _methodLabel(BuildContext context, String method) {
    return switch (method) {
      _autoValue => context.l10n.prayerMethodAuto,
      'egyptian' => context.l10n.prayerMethodEgyptian,
      'umm_al_qura' => context.l10n.prayerMethodUmmAlQura,
      'karachi' => context.l10n.prayerMethodKarachi,
      'north_america' => context.l10n.prayerMethodNorthAmerica,
      'dubai' => context.l10n.prayerMethodDubai,
      'kuwait' => context.l10n.prayerMethodKuwait,
      'qatar' => context.l10n.prayerMethodQatar,
      'singapore' => context.l10n.prayerMethodSingapore,
      'turkey' => context.l10n.prayerMethodTurkey,
      'moon_sighting_committee' => context.l10n.prayerMethodMoonSighting,
      _ => context.l10n.prayerMethodMwl,
    };
  }

  String _madhabLabel(BuildContext context, String madhab) {
    return switch (madhab) {
      _autoValue => context.l10n.prayerMadhabAuto,
      PrayerTimesService.hanafiMadhab => context.l10n.prayerMadhabHanafi,
      _ => context.l10n.prayerMadhabShafi,
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
                DropdownMenuItem(
                  value: PrayerTimesService.customCityId,
                  child: Text(context.l10n.prayerCustomLocation),
                ),
              ],
              onChanged: _setCountry,
            ),
          ),
          SettingsDivider(isDark: widget.isDark),
          if (_countryId == PrayerTimesService.customCityId)
            _CustomLocationFields(
              latitudeController: _latitudeController,
              longitudeController: _longitudeController,
              deviceZone: _deviceZone,
              onSave: _saveCustomLocation,
            )
          else
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
              value: _methodAuto || !_methods.contains(_method)
                  ? _autoValue
                  : _method,
              items: [
                for (final method in [_autoValue, ..._methods])
                  DropdownMenuItem(
                    value: method,
                    child: Text(_methodLabel(context, method)),
                  ),
              ],
              onChanged: _setMethod,
            ),
          ),
          SettingsDivider(isDark: widget.isDark),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.prayerMadhabTitle),
            subtitle: DropdownButton<String>(
              key: const Key('prayer_madhab_dropdown'),
              isExpanded: true,
              value: _madhab ?? _autoValue,
              items: [
                for (final madhab in [
                  _autoValue,
                  PrayerTimesService.shafiMadhab,
                  PrayerTimesService.hanafiMadhab,
                ])
                  DropdownMenuItem(
                    value: madhab,
                    child: Text(_madhabLabel(context, madhab)),
                  ),
              ],
              onChanged: _setMadhab,
            ),
          ),
        ],
      ],
    );
  }
}

class _CustomLocationFields extends StatelessWidget {
  const _CustomLocationFields({
    required this.latitudeController,
    required this.longitudeController,
    required this.deviceZone,
    required this.onSave,
  });

  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final String? deviceZone;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    const keyboard = TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    );
    final zone = deviceZone;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.prayerCustomHint),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('prayer_custom_latitude'),
                  controller: latitudeController,
                  keyboardType: keyboard,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: context.l10n.prayerCustomLatitude,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const Key('prayer_custom_longitude'),
                  controller: longitudeController,
                  keyboardType: keyboard,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: context.l10n.prayerCustomLongitude,
                  ),
                ),
              ),
            ],
          ),
          if (zone != null) ...[
            const SizedBox(height: 8),
            Text(context.l10n.prayerCustomTimeZone(zone)),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              key: const Key('prayer_custom_save'),
              onPressed: onSave,
              child: Text(context.l10n.prayerCustomSave),
            ),
          ),
        ],
      ),
    );
  }
}
