import 'dart:async';

import '../../../core/progress/progress_changed_reason.dart';
import '../../../core/progress/progress_events_bus.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/sync/cloud_sync_queue.dart';
import '../../../core/utils/talia_logger.dart';
import '../../memorization_plus/domain/repositories/memorization_cloud_repository.dart';
import '../../quran/data/datasources/bookmark_service.dart';
import '../domain/repositories/auth_repository.dart';

/// Owns authenticated cloud synchronization without depending on auth UI state.
///
/// Pulls always finish before any regular push begins, so stale local data cannot
/// overwrite a more recent cloud copy. Queue retries and app-resume recovery are
/// also kept here to make every sync entry point follow the same rules.
class CloudSyncCoordinator {
  CloudSyncCoordinator({
    required AuthRepository authRepository,
    MemorizationCloudRepository? memorizationCloudRepository,
    ProgressEventsBus? progressEvents,
    AchievementService? achievementService,
    CloudSyncQueue? cloudSyncQueue,
    BookmarkService? bookmarkService,
    Duration localChangeDebounce = const Duration(seconds: 2),
  }) : _authRepository = authRepository,
       _memorizationCloudRepository = memorizationCloudRepository,
       _progressEvents = progressEvents,
       _achievementService = achievementService,
       _cloudSyncQueue = cloudSyncQueue,
       _bookmarkService = bookmarkService,
       _localChangeDebounce = localChangeDebounce {
    _progressSubscription = _progressEvents?.changes
        .where((reason) => reason != ProgressChangedReason.cloudPull)
        .listen(_schedulePendingPush);
  }

  final AuthRepository _authRepository;
  final MemorizationCloudRepository? _memorizationCloudRepository;
  final ProgressEventsBus? _progressEvents;
  final AchievementService? _achievementService;
  final CloudSyncQueue? _cloudSyncQueue;
  final BookmarkService? _bookmarkService;
  final Duration _localChangeDebounce;

  Future<void>? _syncInFlight;
  Future<void>? _pendingPushInFlight;
  StreamSubscription<ProgressChangedReason>? _progressSubscription;
  Timer? _localChangeTimer;
  var _pendingPushRequested = false;
  var _pushKidsProgressAfterLocalChange = false;
  DateTime? _lastResumeSyncAt;
  static const _resumeDebounce = Duration(minutes: 5);

  Future<void> dispose() async {
    _localChangeTimer?.cancel();
    await _progressSubscription?.cancel();
  }

  /// Starts a full cloud reconciliation, coalescing concurrent requests.
  /// Unexpected exceptions are logged and contained so authentication UI and
  /// lifecycle observers remain responsive while offline services recover.
  Future<void> run() {
    final pendingPush = _pendingPushInFlight;
    if (pendingPush != null) {
      return pendingPush.then((_) => run());
    }
    _syncInFlight ??= _perform()
        .catchError((Object error, StackTrace stackTrace) {
          TaliaLogger.e('Unexpected cloud sync failure', error, stackTrace);
        })
        .whenComplete(() => _syncInFlight = null);
    return _syncInFlight!;
  }

  /// Coalesces local writes into a push-only operation. Local progress changes
  /// must not trigger another full remote pull: the next login/resume still
  /// performs reconciliation, while this path uploads only outstanding work.
  void _schedulePendingPush(ProgressChangedReason reason) {
    if (_authRepository.currentUser == null) return;
    if (reason == ProgressChangedReason.kidsProgress) {
      _pushKidsProgressAfterLocalChange = true;
    }
    _localChangeTimer?.cancel();
    _localChangeTimer = Timer(_localChangeDebounce, () {
      _localChangeTimer = null;
      unawaited(_pushPendingChanges());
    });
  }

  Future<void> _pushPendingChanges() async {
    _pendingPushRequested = true;
    _pendingPushInFlight ??= _drainPendingPushes()
        .catchError((Object error, StackTrace stackTrace) {
          TaliaLogger.e(
            'Unexpected pending cloud push failure',
            error,
            stackTrace,
          );
        })
        .whenComplete(() => _pendingPushInFlight = null);
    await _pendingPushInFlight;
  }

  Future<void> _drainPendingPushes() async {
    do {
      _pendingPushRequested = false;
      final fullSync = _syncInFlight;
      if (fullSync != null) {
        await fullSync;
      }
      await _performPendingPushes();
    } while (_pendingPushRequested);
  }

  /// Syncs on app recovery only when non-exhausted deferred work exists
  /// (unless [force] is requested). Dead letters require an explicit recovery
  /// action and are never silently re-armed by an application lifecycle event.
  Future<void> resumeIfNeeded({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastResumeSyncAt != null &&
        now.difference(_lastResumeSyncAt!) < _resumeDebounce) {
      return;
    }

    if (!force && !await _hasPendingSyncWork()) {
      TaliaLogger.i('Skipping resume sync — no pending outbox/cursor work');
      return;
    }
    _lastResumeSyncAt = now;
    await run();
  }

  /// Best-effort pre-sign-out flush. Its result tells the caller whether it is
  /// safe to discard account-owned local data.
  ///
  /// This is the single authoritative all-domain pending-work decision: it
  /// covers bookmarks, memorization, and auth progress (V1-M5). Omitting any
  /// dirty domain here would let sign-out destroy unsynced user data.
  Future<bool> flushBeforeSignOut() async {
    try {
      final bookmarks = _bookmarkService;
      if (bookmarks != null && bookmarks.hasPendingCloudWork) {
        await bookmarks.pushToCloud();
      }
      final memorization = _memorizationCloudRepository;
      if (memorization != null && await memorization.hasPendingCloudWork()) {
        await memorization.resyncProductionDataToCloud();
        await memorization.syncKidsProgressToCloud();
      }
      if (await _authRepository.hasPendingCloudPush()) {
        await _authRepository.syncProgressToCloud();
      }
      await _processSyncQueue();
      final memorizationPending =
          memorization != null && await memorization.hasPendingCloudWork();
      return !memorizationPending &&
          !(_bookmarkService?.hasPendingCloudWork ?? false) &&
          !await _authRepository.hasPendingCloudPush();
    } catch (error, stackTrace) {
      TaliaLogger.w(
        'Best-effort cloud flush before sign-out failed; local data will be cleared',
        error,
        stackTrace,
      );
      return false;
    }
  }

  Future<void> _perform() async {
    await _processSyncQueue();

    final bookmarks = _bookmarkService;
    if (bookmarks != null) {
      try {
        await bookmarks.migrateLegacyForCurrentOwner();
        await bookmarks.pullFromCloud();
        await _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.bookmarkPull);
      } catch (error, stackTrace) {
        TaliaLogger.w('Bookmark cloud pull failed', error, stackTrace);
        await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.bookmarkPull);
      }
    }

    final pullResult = await _authRepository.pullProgressFromCloud();
    await pullResult.fold(
      (failure) async {
        TaliaLogger.w('Cloud pull failed after login', failure.message);
        await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.authPull);
      },
      (_) async {
        TaliaLogger.i('Streak/heatmap pull completed');
        await _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.authPull);
      },
    );

    final memorization = _memorizationCloudRepository;
    if (memorization != null) {
      final identityPull = await memorization.pullIdentityFromCloud();
      identityPull.fold(
        (failure) => TaliaLogger.w('Identity pull failed', failure.message),
        (_) => TaliaLogger.i('Identity pull completed'),
      );

      final productionPull = await memorization.pullProductionDataFromCloud();
      await productionPull.fold(
        (failure) async {
          TaliaLogger.w('Production SRS pull failed', failure.message);
          await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.productionPull);
        },
        (_) async {
          TaliaLogger.i('Production SRS pull completed');
          await _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.productionPull);
        },
      );

      final achievementService = _achievementService;
      if (achievementService != null) {
        final certificatePull = await memorization.pullCertificatesFromCloud();
        await certificatePull.fold(
          (failure) async {
            TaliaLogger.w('Certificate pull failed', failure.message);
            await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.certificatePull);
          },
          (awards) async {
            if (awards.isNotEmpty) {
              await achievementService.mergeEarnedFromCloud(
                awards,
                isKids: false,
              );
            }
            await achievementService.checkAndUnlockCertificates(isKids: true);
          },
        );
      }

      final kidsPull = await memorization.pullKidsProgressFromCloud();
      await kidsPull.fold(
        (failure) async {
          TaliaLogger.w('Kids progress pull failed', failure.message);
          await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.kidsProgressPull);
        },
        (_) async {
          TaliaLogger.i('Kids progress pull completed');
          await _cloudSyncQueue?.markSuccess(
            CloudSyncQueueKind.kidsProgressPull,
          );
        },
      );
    }

    await _pushAllData();

    _progressEvents?.notify(ProgressChangedReason.cloudPull);
  }

  Future<void> _pushAllData() async {
    await _pushAuthProgress();

    final memorization = _memorizationCloudRepository;
    if (memorization != null) {
      await _pushProductionData(memorization);
      await _pushKidsProgress(memorization);
      await _pushIdentity(memorization);
      await _pushCertificates(memorization);
    }

    final bookmarks = _bookmarkService;
    if (bookmarks != null) {
      await _pushBookmarks(bookmarks);
    }
  }

  Future<void> _performPendingPushes() async {
    if (await _authRepository.hasPendingCloudPush()) {
      await _pushAuthProgress();
    }

    final memorization = _memorizationCloudRepository;
    if (memorization != null) {
      if (await memorization.hasPendingCloudWork()) {
        await _pushProductionData(memorization);
      }
      if (_pushKidsProgressAfterLocalChange) {
        _pushKidsProgressAfterLocalChange = false;
        await _pushKidsProgress(memorization);
      }
      await _pushIdentity(memorization);
      await _pushCertificates(memorization);
    }

    final bookmarks = _bookmarkService;
    if (bookmarks != null && bookmarks.hasPendingCloudWork) {
      await _pushBookmarks(bookmarks);
    }
  }

  Future<void> _pushAuthProgress() async {
    final pushResult = await _authRepository.syncProgressToCloud();
    await pushResult.fold(
      (failure) async {
        TaliaLogger.w('Streak/heatmap cloud sync failed', failure.message);
        await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.authPush);
      },
      (_) async {
        TaliaLogger.i('Streak/heatmap cloud sync completed');
        await _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.authPush);
      },
    );
  }

  Future<void> _pushProductionData(
    MemorizationCloudRepository memorization,
  ) async {
    final productionPush = await memorization.resyncProductionDataToCloud();
    await productionPush.fold(
      (failure) async {
        TaliaLogger.w('Production data cloud resync failed', failure.message);
        await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.productionPush);
      },
      (_) async {
        TaliaLogger.i('Production data cloud resync completed');
        await _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.productionPush);
      },
    );
  }

  Future<void> _pushKidsProgress(
    MemorizationCloudRepository memorization,
  ) async {
    final kidsPush = await memorization.syncKidsProgressToCloud();
    await kidsPush.fold(
      (failure) async {
        TaliaLogger.w('Kids progress push failed', failure.message);
        await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.kidsProgressPush);
      },
      (_) async {
        TaliaLogger.i('Kids progress push completed');
        await _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.kidsProgressPush);
      },
    );
  }

  Future<void> _pushIdentity(MemorizationCloudRepository memorization) async {
    final identityPush = await memorization.pushIdentityToCloud();
    identityPush.fold(
      (failure) => TaliaLogger.w('Identity push failed', failure.message),
      (_) => TaliaLogger.i('Identity push completed'),
    );
  }

  Future<void> _pushCertificates(
    MemorizationCloudRepository memorization,
  ) async {
    final achievementService = _achievementService;
    if (achievementService != null) {
      final certificates = achievementService.getAllEarnedCertificates();
      if (certificates.isNotEmpty) {
        final certificatePush = await memorization.pushCertificatesToCloud(
          certificates,
        );
        await certificatePush.fold(
          (failure) async {
            TaliaLogger.w('Certificate cloud push failed', failure.message);
            await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.certificatePush);
          },
          (_) async {
            TaliaLogger.i('Certificate cloud push completed');
            await _cloudSyncQueue?.markSuccess(
              CloudSyncQueueKind.certificatePush,
            );
          },
        );
      }
    }
  }

  Future<void> _pushBookmarks(BookmarkService bookmarks) async {
    try {
      await bookmarks.pushToCloud();
    } catch (error, stackTrace) {
      TaliaLogger.w('Bookmark cloud push failed', error, stackTrace);
    }
    if (bookmarks.hasPendingCloudWork) {
      await _cloudSyncQueue?.enqueue(CloudSyncQueueKind.bookmarkPush);
    } else {
      await _cloudSyncQueue?.markSuccess(CloudSyncQueueKind.bookmarkPush);
    }
  }

  Future<bool> _hasPendingSyncWork() async {
    final queue = _cloudSyncQueue;
    if (queue != null && await queue.hasPending()) return true;
    if (_bookmarkService?.hasPendingCloudWork ?? false) return true;
    if (await _authRepository.hasPendingCloudPush()) return true;
    final memorization = _memorizationCloudRepository;
    return memorization != null && await memorization.hasPendingCloudWork();
  }

  Future<void> _processSyncQueue() async {
    final queue = _cloudSyncQueue;
    if (queue == null) return;
    for (final item in await queue.dueItems()) {
      bool completed;
      try {
        completed = await _retryQueueKind(item.kind);
      } catch (error, stackTrace) {
        TaliaLogger.w(
          'Queued cloud sync retry failed: ${item.kind}',
          error,
          stackTrace,
        );
        completed = false;
      }
      if (completed) {
        await queue.markSuccess(item.kind);
      } else {
        await queue.markFailure(item.kind);
      }
    }
  }

  Future<bool> retryQueueKindForTesting(String kind) => _retryQueueKind(kind);

  Future<bool> _retryQueueKind(String kind) async {
    final memorization = _memorizationCloudRepository;
    switch (kind) {
      case CloudSyncQueueKind.authPull:
        return (await _authRepository.pullProgressFromCloud()).isRight();
      case CloudSyncQueueKind.authPush:
        return (await _authRepository.syncProgressToCloud()).isRight();
      case CloudSyncQueueKind.productionPull:
        return memorization == null ||
            (await memorization.pullProductionDataFromCloud()).isRight();
      case CloudSyncQueueKind.productionPush:
        return memorization == null ||
            (await memorization.resyncProductionDataToCloud()).isRight();
      case CloudSyncQueueKind.certificatePush:
        final achievementService = _achievementService;
        if (memorization == null || achievementService == null) return true;
        final certificates = achievementService.getAllEarnedCertificates();
        return certificates.isEmpty ||
            (await memorization.pushCertificatesToCloud(
              certificates,
            )).isRight();
      case CloudSyncQueueKind.certificatePull:
        return _retryCertificatePull();
      case CloudSyncQueueKind.kidsProgress:
        if (memorization == null) return true;
        if (!(await memorization.pullKidsProgressFromCloud()).isRight()) {
          return false;
        }
        return (await memorization.syncKidsProgressToCloud()).isRight();
      case CloudSyncQueueKind.kidsProgressPull:
        return memorization == null ||
            (await memorization.pullKidsProgressFromCloud()).isRight();
      case CloudSyncQueueKind.kidsProgressPush:
        return memorization == null ||
            (await memorization.syncKidsProgressToCloud()).isRight();
      case CloudSyncQueueKind.bookmarkPull:
        await _bookmarkService?.pullFromCloud();
        return true;
      case CloudSyncQueueKind.bookmarkPush:
        await _bookmarkService?.pushToCloud();
        return !(_bookmarkService?.hasPendingCloudWork ?? false);
      default:
        return true;
    }
  }

  Future<bool> _retryCertificatePull() async {
    final memorization = _memorizationCloudRepository;
    final achievementService = _achievementService;
    if (memorization == null || achievementService == null) return true;
    final result = await memorization.pullCertificatesFromCloud();
    return result.fold<Future<bool>>(
      (failure) async {
        TaliaLogger.w('Certificate pull retry failed', failure.message);
        return false;
      },
      (awards) async {
        if (awards.isNotEmpty) {
          await achievementService.mergeEarnedFromCloud(awards, isKids: false);
        }
        await achievementService.checkAndUnlockCertificates(isKids: true);
        return true;
      },
    );
  }
}
