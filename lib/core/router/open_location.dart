import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// Locations owned by a bottom-navigation tab. Pushing one of them stacks the
/// screen inside the current tab (with that tab still highlighted and no back
/// arrow), so they are opened by switching tabs instead.
const shellTabLocations = {
  AppRoutes.home,
  AppRoutes.quran,
  AppRoutes.memorizationHub,
  AppRoutes.hifzPracticeSurah,
  AppRoutes.azkar,
  AppRoutes.progress,
};

bool isShellTabLocation(String location) =>
    shellTabLocations.contains(Uri.parse(location).path);

extension OpenLocation on BuildContext {
  /// Opens [location]: tab locations switch tabs, others are pushed.
  Future<void> openLocation(String location, {Object? extra}) async {
    if (isShellTabLocation(location)) {
      go(location, extra: extra);
      return;
    }
    await push(location, extra: extra);
  }
}
