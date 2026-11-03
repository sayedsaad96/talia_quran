import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/application/cloud_sync_coordinator.dart';
import '../../features/memorization_plus/domain/repositories/memorization_cloud_repository.dart';
import '../../features/quran/data/datasources/bookmark_service.dart';
import '../../features/quran/data/datasources/quran_local_datasource.dart';
import '../../features/quran/data/services/quran_corpus_bookmark_resolver.dart';
import '../../features/quran/domain/repositories/reading_checkpoint_repository.dart';
import '../../features/quran/presentation/cubits/reading_checkpoint_cubit.dart';
import '../../features/settings/domain/entities/data_protection_status.dart';
import '../../features/settings/presentation/cubits/data_protection_cubit.dart';
import '../backup/portable_signed_in_import.dart';
import '../backup/restore_operation_gate.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../services/app_session_service.dart';
import 'reading_checkpoint_injection.dart';

void configureDataProtection() {
  final locator = GetIt.instance;
  locator.registerFactory<ReadingCheckpointCubit>(
    () => ReadingCheckpointCubit(
      locator<ReadingCheckpointRepository>(),
      locator<RecordOwnerProvider>(),
      AccountDataBarrier.forPreferences(locator<SharedPreferences>()),
    ),
  );
  locator.registerLazySingleton<PortableSignedInImporter>(
    () => PortableSignedInImporter(
      prefs: locator<SharedPreferences>(),
      owner: locator<RecordOwnerProvider>(),
      barrier: AccountDataBarrier.forPreferences(locator<SharedPreferences>()),
      bookmarks: locator<BookmarkService>(),
      resolve: QuranCorpusBookmarkResolver(
        locator<QuranLocalDatasource>(),
      ).call,
      gate: locator<RestoreOperationGate>(),
      readCheckpoint: locator<AppSessionService>().readCheckpointUnderLease,
      writeCheckpoint: locator<AppSessionService>().writeCheckpointUnderLease,
    ),
  );
  locator.registerFactory<DataProtectionCubit>(
    () => DataProtectionCubit(
      () async {
        final owner = locator<RecordOwnerProvider>();
        final ownerId = owner.currentOwnerId;
        final lease = AccountDataBarrier.forPreferences(
          locator<SharedPreferences>(),
        ).capture();
        final states = <ProtectionDomain, ProtectionDomainStatus>{};
        if (owner.isSignedIn) {
          Future<void> pending(
            ProtectionDomain domain,
            Future<bool> Function() check,
          ) async {
            try {
              final hasPending = await check();
              states[domain] = ProtectionDomainStatus(
                hasPending ? ProtectionState.pending : ProtectionState.unknown,
              );
            } catch (_) {
              states[domain] = const ProtectionDomainStatus(
                ProtectionState.failed,
              );
            }
            lease.checkOwner(ownerId);
          }

          await pending(
            ProtectionDomain.progress,
            locator<AuthRepository>().hasPendingCloudPush,
          );
          await pending(
            ProtectionDomain.review,
            locator<MemorizationCloudRepository>().hasPendingReviewEvidence,
          );
          await pending(
            ProtectionDomain.bookmarks,
            locator<BookmarkService>().hasPendingCloudWorkDurably,
          );
          if (checkpointCloudAvailable()) {
            await pending(
              ProtectionDomain.checkpoint,
              () async =>
                  (await locator<ReadingCheckpointRepository>().readLocal(
                    expectedOwnerId: ownerId,
                  ))?.pendingMutationId !=
                  null,
            );
            final observation = locator<CloudSyncCoordinator>()
                .checkpointStatusFor(ownerId);
            if (states[ProtectionDomain.checkpoint]?.state ==
                    ProtectionState.unknown &&
                observation.result?.status == CheckpointSyncStatus.synced) {
              states[ProtectionDomain.checkpoint] = ProtectionDomainStatus(
                ProtectionState.synced,
                lastSuccess: observation.lastSuccess,
              );
            }
          } else {
            states[ProtectionDomain.checkpoint] = const ProtectionDomainStatus(
              ProtectionState.localOnly,
            );
          }
        }
        lease.checkOwner(ownerId);
        return DataProtectionStatus(
          signedIn: owner.isSignedIn,
          domains: states,
        );
      },
      accountChanges: AccountDataBarrier.forPreferences(
        locator<SharedPreferences>(),
      ).changes,
    ),
  );
}
