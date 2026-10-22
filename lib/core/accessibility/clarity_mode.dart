import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/injection.dart';

/// Minimum text scale applied while clarity mode is on.
const double kClarityTextScale = 1.3;

/// Device-level preference key for clarity mode.
const String kClarityModePreferenceKey = 'clarity_mode_on';

/// The text scaler to use app-wide: the system scale, but never below
/// [kClarityTextScale] while [on]. Off returns [system] untouched.
TextScaler clarityTextScaler(TextScaler system, {required bool on}) {
  if (!on) return system;
  return TextScaler.linear(math.max(system.scale(1), kClarityTextScale));
}

/// Device-level clarity mode (larger text, high contrast, simpler home).
///
/// Effective only while the rollout flag is enabled; turning the flag off
/// restores the previous UI without deleting the stored preference.
class ClarityModeController extends ChangeNotifier {
  ClarityModeController(this._prefs, {required this.flagEnabled});

  final SharedPreferences _prefs;
  final bool Function() flagEnabled;

  bool get isOn {
    try {
      return flagEnabled() &&
          (_prefs.getBool(kClarityModePreferenceKey) ?? false);
    } catch (_) {
      return false;
    }
  }

  /// The stored preference, regardless of the rollout flag.
  bool get preference => _prefs.getBool(kClarityModePreferenceKey) ?? false;

  bool get isAvailable {
    try {
      return flagEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<void> setOn(bool on) async {
    await _prefs.setBool(kClarityModePreferenceKey, on);
    notifyListeners();
  }

  /// The registered controller, or null when none is wired (tests, early boot).
  static ClarityModeController? maybeInstance() =>
      getIt.isRegistered<ClarityModeController>()
      ? getIt<ClarityModeController>()
      : null;

  /// True when clarity mode is registered and currently on.
  static bool get isActive => maybeInstance()?.isOn ?? false;
}

/// Carries the unmodified system text scaler below the app-wide clarity
/// override, so fixed-glyph content (the Mushaf) can opt back out.
class SystemTextScalerScope extends InheritedWidget {
  const SystemTextScalerScope({
    super.key,
    required this.scaler,
    required super.child,
  });

  final TextScaler scaler;

  static TextScaler? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SystemTextScalerScope>()
      ?.scaler;

  @override
  bool updateShouldNotify(SystemTextScalerScope oldWidget) =>
      scaler != oldWidget.scaler;
}

/// Restores the system text scale for [child] (Mushaf pages use fixed glyph
/// fonts per page, so clarity scaling must not reach them).
class SystemTextScale extends StatelessWidget {
  const SystemTextScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final system = SystemTextScalerScope.maybeOf(context);
    if (system == null) return child;
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: system),
      child: child,
    );
  }
}

/// Applies [clarityTextScaler] to descendants while keeping the system scaler
/// available through [SystemTextScalerScope].
class ClarityTextScaleScope extends StatelessWidget {
  const ClarityTextScaleScope({
    super.key,
    required this.on,
    required this.child,
  });

  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return SystemTextScalerScope(
      scaler: mq.textScaler,
      child: MediaQuery(
        data: mq.copyWith(textScaler: clarityTextScaler(mq.textScaler, on: on)),
        child: child,
      ),
    );
  }
}
