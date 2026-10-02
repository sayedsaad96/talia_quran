import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Durable boundary between a confirmed server-side account deletion and the
/// device cleanup that must follow it.  The marker makes cleanup resumable
/// after an app termination without ever repeating the destructive RPC.
abstract final class AccountDeletionMarker {
  static const _ownerKey = 'account_deletion_owner';
  static const _stageKey = 'account_deletion_stage';
  static const _completedOwnerKey = 'account_deletion_completed_owner';
  static const requestedStage = 'requested';
  static const remoteConfirmedStage = 'remote_confirmed';

  static String? pendingOwnerId(SharedPreferences prefs) {
    if (stage(prefs) != remoteConfirmedStage) return null;
    return ownerId(prefs);
  }

  static String? pendingOperationOwnerId(SharedPreferences prefs) =>
      ownerId(prefs);

  static String? ownerId(SharedPreferences prefs) {
    final ownerId = prefs.getString(_ownerKey);
    return ownerId == null || ownerId.isEmpty ? null : ownerId;
  }

  static String? stage(SharedPreferences prefs) => prefs.getString(_stageKey);

  static bool hasPendingOperation(SharedPreferences prefs) =>
      ownerId(prefs) != null;

  /// A short-lived local fence for queues that may wake in another engine
  /// after cleanup clears the pending transaction marker.
  static bool isOwnerBlocked(SharedPreferences prefs, String ownerId) =>
      ownerId == AccountDeletionMarker.ownerId(prefs) ||
      _ownerDigest(ownerId) == prefs.getString(_completedOwnerKey);

  static String _ownerDigest(String ownerId) =>
      sha256.convert(utf8.encode(ownerId)).toString();

  static Future<bool> markRequested(
    SharedPreferences prefs,
    String ownerId,
  ) async {
    final storedOwner = await prefs.setString(_ownerKey, ownerId);
    final storedStage = await prefs.setString(_stageKey, requestedStage);
    return storedOwner && storedStage;
  }

  static Future<bool> markRemoteConfirmed(SharedPreferences prefs) =>
      prefs.setString(_stageKey, remoteConfirmedStage);

  static Future<bool> clear(SharedPreferences prefs) async {
    final clearedStage = await prefs.remove(_stageKey);
    final clearedOwner = await prefs.remove(_ownerKey);
    return clearedStage && clearedOwner;
  }

  static Future<bool> completeAndClear(
    SharedPreferences prefs,
    String ownerId,
  ) async {
    final completed = await prefs.setString(
      _completedOwnerKey,
      _ownerDigest(ownerId),
    );
    if (!completed) return false;
    return clear(prefs);
  }
}
