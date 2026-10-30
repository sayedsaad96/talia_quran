import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/entities/memorization_profile.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

/// Prevents an authorization dialog from outliving its account or profile.
class GuardianLinkScope {
  GuardianLinkScope._(this._owner, this._lease, this._profile);
  final String _owner;
  final AccountDataLease _lease;
  final MemorizationProfile _profile;

  static Future<GuardianLinkScope?> capture() async {
    try {
      final owner = getIt<RecordOwnerProvider>().currentOwnerId;
      final lease = AccountDataBarrier.forPreferences(
        getIt<SharedPreferences>(),
      ).capture();
      lease.checkOwner(owner);
      final profile =
          (await getIt<MemorizationPlusRepository>().getMemorizationProfile())
              .fold((_) => null, (p) => p);
      lease.checkOwner(owner);
      return profile == null
          ? null
          : GuardianLinkScope._(owner, lease, profile);
    } on AccountDataUnavailableException {
      return null;
    }
  }

  Stream<void> get changes => _lease.changes;

  bool get active {
    try {
      _lease.checkOwner(_owner);
      return getIt<RecordOwnerProvider>().currentOwnerId == _owner;
    } on AccountDataUnavailableException {
      return false;
    }
  }

  Future<bool> stillValid() async {
    if (!active) return false;
    final profile =
        (await getIt<MemorizationPlusRepository>().getMemorizationProfile())
            .fold((_) => null, (p) => p);
    // An unconfigured profile is recreated on read; its timestamps are not
    // part of the identity that authorized this operation.
    return active &&
        profile != null &&
        profile.copyWith(
              createdAt: _profile.createdAt,
              updatedAt: _profile.updatedAt,
            ) ==
            _profile;
  }
}
