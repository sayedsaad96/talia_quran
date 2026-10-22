import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../features/kids_encouragement/data/kids_encouragement_repository_impl.dart';
import '../../features/kids_encouragement/domain/repositories/kids_encouragement_repository.dart';
import '../../features/kids_encouragement/presentation/cubits/child_encouragement_inbox_cubit.dart';
import '../../features/kids_encouragement/presentation/cubits/parent_encouragement_composer_cubit.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../memorization/kids_enrichment_feature_flags.dart';

void registerKidsEncouragementDependencies(GetIt services) {
  services.registerLazySingleton<KidsEncouragementRepository>(
    () => KidsEncouragementRepositoryImpl(
      prefs: services<SharedPreferences>(),
      owner: services<RecordOwnerProvider>(),
      barrier: _barrier(services),
      isEnabled: () => services<KidsEnrichmentFlags>().isEnabled(
        KidsEnrichmentFeature.encouragements,
      ),
      rpc: (function, params) =>
          _client(services).rpc(function, params: params),
      selectSeen: (ids) async {
        final rows = await _client(services)
            .from('kids_encouragements')
            .select('id,child_user_id,seen_at')
            .eq('child_user_id', services<RecordOwnerProvider>().currentOwnerId)
            .inFilter('id', ids)
            .not('seen_at', 'is', null);
        return rows.map((row) => Map<String, dynamic>.from(row)).toList();
      },
      selectForChild: (childId) async {
        final rows = await _client(services)
            .from('kids_encouragements')
            .select()
            .eq('child_user_id', childId)
            .isFilter('seen_at', null)
            .order('created_at')
            .order('id')
            .limit(100);
        return rows.map((row) => Map<String, dynamic>.from(row)).toList();
      },
    ),
  );
  services.registerFactory<ParentEncouragementComposerCubit>(
    () => ParentEncouragementComposerCubit(
      repository: services<KidsEncouragementRepository>(),
      owner: services<RecordOwnerProvider>(),
      barrier: _barrier(services),
      accountChanges: _barrier(services).changes,
      newRequestId: const Uuid().v4,
    ),
  );
  services.registerFactory<ChildEncouragementInboxCubit>(
    () => ChildEncouragementInboxCubit(
      repository: services<KidsEncouragementRepository>(),
      owner: services<RecordOwnerProvider>(),
      barrier: _barrier(services),
      accountChanges: _barrier(services).changes,
    ),
  );
}

AccountDataBarrier _barrier(GetIt services) =>
    AccountDataBarrier.forPreferences(services<SharedPreferences>());

SupabaseClient _client(GetIt services) {
  final client = Supabase.instance.client;
  if (client.auth.currentUser?.id !=
      services<RecordOwnerProvider>().currentOwnerId) {
    throw const AccountDataUnavailableException();
  }
  return client;
}
