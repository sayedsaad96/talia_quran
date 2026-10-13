import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../domain/entities/kids_learning_support_profile.dart';
import '../../domain/repositories/kids_support_profile_repository.dart';

/// Owner-scoped, versioned record of the guardian's support answers for the
/// child on this device. Cleared with the rest of the account's data on an
/// account switch (`AccountDataReset`, prefix [keyPrefix]).
class KidsSupportProfileStore implements KidsSupportProfileRepository {
  KidsSupportProfileStore(this._prefs, this._owner);

  static const keyPrefix = 'kids_support_profile_';

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  String get _key => '$keyPrefix${_owner.currentOwnerId}';

  @override
  KidsLearningSupportProfile read() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return KidsLearningSupportProfile.unknown;
      return KidsLearningSupportProfile.fromJson(jsonDecode(raw));
    } catch (_) {
      return KidsLearningSupportProfile.unknown;
    }
  }

  /// Saves under the account barrier, so a write can never land after (or
  /// during) an account reset. False when the account changed or the write
  /// failed; nothing is written for another account.
  @override
  Future<bool> save(KidsLearningSupportProfile profile) async {
    final key = _key;
    try {
      return await AccountDataBarrier.forPreferences(_prefs).run((lease) async {
        if (key != _key) return false;
        final saved = await _prefs.setString(key, jsonEncode(profile.toJson()));
        lease.check();
        return saved;
      });
    } on AccountDataUnavailableException {
      return false;
    } catch (error, stack) {
      // A platform write failure is reported as "not saved", never thrown
      // into the guardian's editor.
      TaliaLogger.w('Kids support profile not saved', error, stack);
      return false;
    }
  }
}
