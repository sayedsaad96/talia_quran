import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/error/app_failure.dart';
import '../../../../../core/memorization/cloud_sync_feature_flags.dart';

/// Encapsulates all Supabase access plumbing shared across cloud collaborators:
/// readiness checks, client access, feature-flag gating, RPC fallback detection
/// and parent/child link lookups.
class MemorizationCloudGateway {
  MemorizationCloudGateway(this._prefs);

  final SharedPreferences _prefs;

  bool get isSupabaseReady {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get cloudPullEnabled =>
      CloudSyncFeatureFlags.isProductionPullEnabled(_prefs);

  SupabaseClient get supabase {
    if (!isSupabaseReady) {
      throw StateError('Supabase is not initialized');
    }
    return Supabase.instance.client;
  }

  Either<Failure, SupabaseClient> supabaseOrFailure() {
    if (!isSupabaseReady) {
      return const Left(
        NetworkFailure('المزامنة السحابية غير مهيأة في هذا الإصدار'),
      );
    }
    return Right(supabase);
  }

  bool isMissingRpc(PostgrestException error, String rpcName) {
    final message = error.message.toLowerCase();
    return message.contains(rpcName.toLowerCase()) ||
        message.contains('could not find the function');
  }

  Future<String?> activeGuardianIdForChild(String childUserId) async {
    final links = await supabase
        .from('parent_child_links')
        .select('parent_user_id')
        .eq('child_user_id', childUserId)
        .eq('status', 'active')
        .order('linked_at', ascending: false)
        .limit(1);
    if (links.isEmpty) return null;
    return links.first['parent_user_id'] as String?;
  }

  Future<String?> latestActiveChildIdForParent(String parentUserId) async {
    final links = await supabase
        .from('parent_child_links')
        .select('child_user_id')
        .eq('parent_user_id', parentUserId)
        .eq('status', 'active')
        .order('linked_at', ascending: false)
        .limit(1);
    if (links.isEmpty) return null;
    return links.first['child_user_id'] as String?;
  }
}
