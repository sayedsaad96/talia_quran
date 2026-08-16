import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';

abstract class ProgressLocalDatasource {
  List<int> getReadPages();
  Future<void> saveReadPage(int pageNumber);
}

class ProgressLocalDatasourceImpl implements ProgressLocalDatasource {
  ProgressLocalDatasourceImpl(this._prefs);
  final SharedPreferences _prefs;

  /// SharedPreferences key set to `true` after any [saveReadPage] call.
  /// Cleared by [AuthRepositoryImpl.syncProgressToCloud] after a successful push.
  static const kReadPagesCloudDirty = 'read_pages_cloud_dirty';

  @override
  List<int> getReadPages() {
    final raw = _prefs.getString(AppConstants.kReadPages);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final pages = <int>[];
      for (final item in list) {
        if (item is int && item >= 1 && item <= 604 && !pages.contains(item)) {
          pages.add(item);
        }
      }
      return pages;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveReadPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) {
      throw ArgumentError.value(pageNumber, 'pageNumber', 'Must be 1..604');
    }
    final pages = getReadPages();
    if (!pages.contains(pageNumber)) {
      pages.add(pageNumber);
      final saved = await _prefs.setString(
        AppConstants.kReadPages,
        jsonEncode(pages),
      );
      if (!saved) {
        throw StateError('Failed to save read page');
      }
      // Mark dirty so auth repository pushes this to cloud on next sync.
      await _prefs.setBool(kReadPagesCloudDirty, true);
    }
  }
}
