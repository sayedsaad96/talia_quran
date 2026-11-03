import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/quran/data/repositories/reading_checkpoint_remote_adapter.dart';
import '../../features/quran/data/repositories/reading_checkpoint_repository_impl.dart';
import '../../features/quran/domain/repositories/reading_checkpoint_repository.dart';
import '../backup/portable_reading_data.dart';
import '../experience/experience_feature_flags.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../memorization/review_record_identity.dart';
import '../security/encrypted_account_preferences_store.dart';

bool checkpointCloudAvailable() {
  final locator = GetIt.instance;
  return locator.isRegistered<ExperienceFlags>() &&
      locator<ExperienceFlags>().isEnabled(
        ExperienceFeature.readingCheckpointCloud,
      );
}

Iterable<String> activeCheckpointPreferenceKeys(String ownerId) =>
    ownerId == ReviewRecordIdentity.localOwnerId
    ? const [ReadingCheckpointRepositoryImpl.guestStorageKey]
    : const [];

void configureReadingCheckpoints() {
  final locator = GetIt.instance;
  locator.registerLazySingleton<ReadingCheckpointRepositoryImpl>(
    () => ReadingCheckpointRepositoryImpl(
      prefs: locator<SharedPreferences>(),
      owner: locator<RecordOwnerProvider>(),
      barrier: AccountDataBarrier.forPreferences(locator<SharedPreferences>()),
      secureStore: locator<EncryptedAccountPreferencesStore>(),
      remote: ReadingCheckpointRemoteAdapter((name, {params}) async {
        if (!checkpointCloudAvailable()) {
          throw StateError('Checkpoint cloud is disabled');
        }
        return Supabase.instance.client.rpc(name, params: params);
      }),
    ),
  );
  locator.registerLazySingleton<ReadingCheckpointRepository>(
    () => locator<ReadingCheckpointRepositoryImpl>(),
  );
}

Future<QuranReadingCheckpoint?> readActiveReadingCheckpoint(
  String owner,
  AccountDataLease lease,
) async {
  final locator = GetIt.instance;
  final position = await locator<ReadingCheckpointRepositoryImpl>()
      .readUnderLease(expectedOwnerId: owner, lease: lease);
  return position == null
      ? null
      : QuranReadingCheckpoint(pageNumber: position.pageNumber);
}

Future<void> writeActiveReadingCheckpoint(
  String owner,
  int page,
  AccountDataLease lease,
) async {
  await GetIt.instance<ReadingCheckpointRepositoryImpl>().writeUnderLease(
    expectedOwnerId: owner,
    pageNumber: page,
    lease: lease,
  );
  // AppSessionService owns the local compatibility page write afterwards.
}
