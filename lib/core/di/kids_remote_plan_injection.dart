import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../memorization/kids_enrichment_feature_flags.dart';

/// Null retains daily scheduling. Zero suppresses reminders for unavailable
/// account data, preventing another account's schedule being reused.
Future<int?> readKidsPracticeDays(GetIt services) async {
  if (!services<KidsEnrichmentFlags>().isEnabled(
    KidsEnrichmentFeature.remotePlan,
  )) {
    return null;
  }
  final ownerId = services<RecordOwnerProvider>().currentOwnerId;
  final authority = AccountDataBarrier.forPreferences(
    services<SharedPreferences>(),
  ).capture();
  authority.checkOwner(ownerId);
  final repository = services<MemorizationPlusRepository>();
  final profile = await repository.getMemorizationProfile();
  authority.checkOwner(ownerId);
  final isChild = profile.fold(
    (failure) => throw failure,
    (value) => value.isChild,
  );
  if (!isChild) return null;
  final settings = await repository.getParentSettings();
  authority.checkOwner(ownerId);
  if (!services<KidsEnrichmentFlags>().isEnabled(
    KidsEnrichmentFeature.remotePlan,
  )) {
    return null;
  }
  return settings.fold(
    (failure) => throw failure,
    (value) => value.remotePlan.sanitized().practiceDays,
  );
}
