import 'package:supabase_flutter/supabase_flutter.dart';

import '../memorization/review_record_identity.dart';

/// Supplies the account that owns data being written right now.
///
/// The memorization data layer depends on this instead of the auth feature so
/// persistence never imports presentation or feature code.
abstract interface class RecordOwnerProvider {
  /// The authenticated user id, or [ReviewRecordIdentity.localOwnerId] when no
  /// account is signed in. Never empty, never null.
  String get currentOwnerId;

  /// False when [currentOwnerId] is the reserved local owner.
  bool get isSignedIn;
}

/// Reads the owner from the active Supabase session.
class SupabaseRecordOwnerProvider implements RecordOwnerProvider {
  const SupabaseRecordOwnerProvider();

  @override
  String get currentOwnerId {
    final id = _currentUserId();
    return (id == null || id.isEmpty)
        ? ReviewRecordIdentity.localOwnerId
        : id;
  }

  @override
  bool get isSignedIn => currentOwnerId != ReviewRecordIdentity.localOwnerId;

  String? _currentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      // Supabase was never initialized (offline build / missing config).
      return null;
    }
  }
}

/// Test and migration double with a caller-supplied owner.
class FixedRecordOwnerProvider implements RecordOwnerProvider {
  const FixedRecordOwnerProvider(this.currentOwnerId);

  @override
  final String currentOwnerId;

  @override
  bool get isSignedIn => currentOwnerId != ReviewRecordIdentity.localOwnerId;
}
