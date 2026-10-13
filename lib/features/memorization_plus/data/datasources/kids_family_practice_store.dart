import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../domain/entities/kids_family_practice_receipt.dart';
import '../../domain/repositories/kids_family_practice_repository.dart';

/// Owner-scoped list of guardian-confirmed «نتعلم سوا» receipts, newest
/// kept up to [maxReceipts]. Cleared with the account's data on an account
/// switch (`AccountDataReset`, prefix [keyPrefix]).
class KidsFamilyPracticeStore implements KidsFamilyPracticeRepository {
  KidsFamilyPracticeStore(this._prefs, this._owner, {this.onRecorded});

  /// Runs after a new receipt is saved (DI refreshes the kids progress, so
  /// the milestone and the world update without waiting for a reload).
  final void Function()? onRecorded;

  static const keyPrefix = 'kids_family_practice_';
  static const maxReceipts = 200;

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  String get _key => '$keyPrefix${_owner.currentOwnerId}';

  @override
  List<KidsFamilyPracticeReceipt> receipts() => _read(_key);

  List<KidsFamilyPracticeReceipt> _read(String key) {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded) ?KidsFamilyPracticeReceipt.tryParse(item),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> record(KidsFamilyPracticeReceipt receipt) async {
    final saved = await _record(receipt);
    if (saved == _Recorded.added) {
      try {
        onRecorded?.call();
      } catch (error, stack) {
        TaliaLogger.w('Family practice listener failed', error, stack);
      }
    }
    return saved != _Recorded.failed;
  }

  Future<_Recorded> _record(KidsFamilyPracticeReceipt receipt) async {
    final key = _key;
    try {
      return await AccountDataBarrier.forPreferences(_prefs).run((lease) async {
        if (key != _key) return _Recorded.failed;
        final existing = _read(key);
        if (existing.any((r) => r.id == receipt.id)) {
          return _Recorded.alreadyThere;
        }
        final next = [...existing, receipt]
          ..sort((a, b) => a.confirmedAt.compareTo(b.confirmedAt));
        final kept = next.length > maxReceipts
            ? next.sublist(next.length - maxReceipts)
            : next;
        final saved = await _prefs.setString(
          key,
          jsonEncode([for (final r in kept) r.toJson()]),
        );
        lease.check();
        return saved ? _Recorded.added : _Recorded.failed;
      });
    } on AccountDataUnavailableException {
      return _Recorded.failed;
    } catch (error, stack) {
      TaliaLogger.w('Family practice receipt not saved', error, stack);
      return _Recorded.failed;
    }
  }
}

enum _Recorded { added, alreadyThere, failed }
