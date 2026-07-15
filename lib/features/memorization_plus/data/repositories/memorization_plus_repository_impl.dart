import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/memorization/cloud_sync_feature_flags.dart';
import '../../../../core/memorization/progress_metrics_service.dart';
import '../../../../core/memorization/remote_child_production_summary_builder.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/memorization/review_record_cloud_merge.dart';
import '../../../../core/memorization/review_record_filters.dart';
import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../../core/services/streak_reader.dart';
import '../../../../features/quran/domain/repositories/quran_repository.dart';
import '../../../../features/quran/domain/entities/quran_entities.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../datasources/memorization_plus_local_datasource.dart';
import '../models/memorization_models.dart';

class MemorizationPlusRepositoryImpl implements MemorizationPlusRepository {
  MemorizationPlusRepositoryImpl(
    this._datasource,
    this._quranRepository,
    this._streakReader,
    this._progressEvents,
    this._prefs, [
    this._metrics = const ProgressMetricsService(),
  ]);

  static const _pairingSessionLifetime = Duration(minutes: 10);
  static const _dailyPlanCloudDirtyKey = 'daily_plan_cloud_dirty';

  final MemorizationPlusLocalDatasource _datasource;

  /// For surah ayah counts
  final QuranRepository _quranRepository;

  /// Authoritative streak source — [KidsProgress.currentStreak] is hydrated
  /// from here at read time (not stored in SharedPreferences).
  final StreakReader _streakReader;

  final ProgressEventsBus _progressEvents;
  final SharedPreferences _prefs;
  final ProgressMetricsService _metrics;

  bool get _cloudPullEnabled =>
      CloudSyncFeatureFlags.isProductionPullEnabled(_prefs);

  final Map<String, Future<void>> _kidsAwardLocks = {};

  bool get _isSupabaseReady {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get _supabase {
    if (!_isSupabaseReady) {
      throw StateError('Supabase is not initialized');
    }
    return Supabase.instance.client;
  }

  Either<Failure, SupabaseClient> _supabaseOrFailure() {
    if (!_isSupabaseReady) {
      return const Left(
        NetworkFailure('المزامنة السحابية غير مهيأة في هذا الإصدار'),
      );
    }
    return Right(_supabase);
  }

  // ─── Identity profile ──────────────────────────────────────────────────────
  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async {
    try {
      return Right(await _loadProfile());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemorizationProfile>> selectMemorizationPath(
    MemorizationPath path,
  ) async {
    try {
      final current = await _loadProfile();
      final selected = current.copyWith(
        selectedPath: path,
        guardianLinkStatus: GuardianLinkStatus.none,
        guardianOnboardingStatus: path == MemorizationPath.child
            ? GuardianOnboardingStatus.required
            : GuardianOnboardingStatus.completed,
        isParentGuardian: path == MemorizationPath.adult
            ? current.isParentGuardian
            : false,
        clearGuardianId: true,
        clearLinkedChildId: path == MemorizationPath.child,
      );
      final saved = await _saveProfile(selected);
      await _datasource.saveSelectedTrack(saved.legacyTrack!.name);
      if (path == MemorizationPath.child) {
        await _datasource.setIsParentMode(false);
      }
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemorizationProfile>> continueWithoutGuardian() async {
    try {
      final profile = await _loadProfile();
      if (!profile.isChild) {
        return const Left(
          CacheFailure('Guardian linking is only for children'),
        );
      }
      final saved = await _saveProfile(
        profile.copyWith(
          guardianLinkStatus: GuardianLinkStatus.none,
          guardianOnboardingStatus: GuardianOnboardingStatus.skipped,
          clearGuardianId: true,
        ),
      );
      await _datasource.clearPairingSession();
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PairingSession>> createGuardianPairingSession() async {
    try {
      final profile = await _loadProfile();
      if (!profile.isChild) {
        return const Left(
          CacheFailure('Guardian linking is only for children'),
        );
      }
      if (profile.isGuardianLinked) {
        return const Left(
          CacheFailure('Unlink the current guardian before linking another'),
        );
      }
      final tokenResult = await createChildLinkToken();
      return await tokenResult.fold((failure) async => Left(failure), (
        token,
      ) async {
        final now = DateTime.now();
        final session = PairingSession(
          id: now.microsecondsSinceEpoch.toString(),
          pairingCode: token,
          qrData: 'talia-kids-link:$token',
          createdAt: now,
          expiresAt: now.add(_pairingSessionLifetime),
          status: PairingSessionStatus.pending,
          isUsed: false,
        );
        await _datasource.savePairingSession(
          PairingSessionModel.fromEntity(session),
        );
        await _saveProfile(
          profile.copyWith(
            guardianLinkStatus: GuardianLinkStatus.pending,
            guardianOnboardingStatus: GuardianOnboardingStatus.required,
          ),
        );
        return Right(session);
      });
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemorizationProfile>> acceptGuardianPairingCode(
    String codeOrQrData,
  ) async {
    try {
      final result = await acceptChildLinkToken(codeOrQrData);
      return await result.fold((failure) async => Left(failure), (_) async {
        final clientResult = _supabaseOrFailure();
        final clientFailure = clientResult.fold(
          (failure) => failure,
          (_) => null,
        );
        if (clientFailure != null) return Left(clientFailure);
        final client = clientResult.getOrElse(
          () => throw StateError('unreachable'),
        );

        final userId = client.auth.currentUser?.id;
        final profile = await _loadProfile();
        final linkedChildId = !profile.isChild && userId != null
            ? await _latestActiveChildIdForParent(userId)
            : null;
        final guardianId = profile.isChild && userId != null
            ? await _activeGuardianIdForChild(userId)
            : null;
        final saved = await _saveProfile(
          profile.isChild
              ? profile.copyWith(
                  guardianLinkStatus: GuardianLinkStatus.linked,
                  guardianOnboardingStatus: GuardianOnboardingStatus.completed,
                  guardianId: guardianId ?? userId,
                )
              : profile.copyWith(
                  isParentGuardian: true,
                  linkedChildId: linkedChildId,
                ),
        );
        await _datasource.setIsParentMode(saved.isParentGuardian);
        final session = await _datasource.getPairingSession();
        if (session != null) {
          await _datasource.savePairingSession(
            PairingSessionModel.fromEntity(
              session.copyWith(
                status: PairingSessionStatus.completed,
                isUsed: true,
                guardianId: userId,
              ),
            ),
          );
        }
        return Right(saved);
      });
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PairingSession?>> refreshPairingSession() async {
    try {
      final session = await _datasource.getPairingSession();
      if (session == null) return const Right(null);
      if (session.status == PairingSessionStatus.pending &&
          DateTime.now().isAfter(session.expiresAt)) {
        final expired = session.copyWith(
          status: PairingSessionStatus.expired,
          failureReason: 'Code expired',
        );
        await _datasource.savePairingSession(
          PairingSessionModel.fromEntity(expired),
        );
        final profile = await _loadProfile();
        if (profile.guardianLinkStatus == GuardianLinkStatus.pending) {
          await _saveProfile(
            profile.copyWith(guardianLinkStatus: GuardianLinkStatus.none),
          );
        }
        return Right(expired);
      }
      return Right(session);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemorizationProfile>> unlinkGuardian() async {
    try {
      final profile = await _loadProfile();
      // Server-side revocation must succeed first: the DB must never disagree
      // with what the child device believes about the link (Phase 5).
      final guardianId = profile.guardianId;
      if (guardianId != null) {
        final revokeResult = await revokeGuardianLink(guardianId);
        final revokeFailure = revokeResult.fold(
          (failure) => failure,
          (_) => null,
        );
        if (revokeFailure != null) return Left(revokeFailure);
      }
      final saved = await _saveProfile(
        profile.copyWith(
          guardianLinkStatus: GuardianLinkStatus.none,
          guardianOnboardingStatus: GuardianOnboardingStatus.completed,
          clearGuardianId: true,
          clearLinkedChildId: true,
        ),
      );
      await _datasource.clearPairingSession();
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
    bool value,
  ) async {
    try {
      final profile = await _loadProfile();
      if (value && profile.selectedPath != MemorizationPath.adult) {
        return const Left(
          CacheFailure('Parent guardian mode is only available for adults'),
        );
      }
      final saved = await _saveProfile(
        profile.copyWith(isParentGuardian: value, clearLinkedChildId: !value),
      );
      await _datasource.setIsParentMode(value);
      if (!value) {
        await _datasource.clearPairingSession();
      }
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemorizationProfile>>
  refreshChildGuardianLink() async {
    try {
      final profile = await _loadProfile();
      if (!profile.isChild) return Right(profile);
      final clientResult = _supabaseOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Right(profile);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      final user = client.auth.currentUser;
      if (user == null) return Right(profile);

      final guardianId = await _activeGuardianIdForChild(user.id);
      if (guardianId != null) {
        final saved = await _saveProfile(
          profile.copyWith(
            guardianLinkStatus: GuardianLinkStatus.linked,
            guardianOnboardingStatus: GuardianOnboardingStatus.completed,
            guardianId: guardianId,
          ),
        );
        final session = await _datasource.getPairingSession();
        if (session != null && session.status == PairingSessionStatus.pending) {
          await _datasource.savePairingSession(
            PairingSessionModel.fromEntity(
              session.copyWith(
                status: PairingSessionStatus.completed,
                isUsed: true,
                guardianId: guardianId,
              ),
            ),
          );
        }
        return Right(saved);
      }

      if (!profile.isGuardianLinked) return Right(profile);

      final saved = await _saveProfile(
        profile.copyWith(
          guardianLinkStatus: GuardianLinkStatus.none,
          guardianOnboardingStatus: GuardianOnboardingStatus.completed,
          clearGuardianId: true,
        ),
      );
      return Right(saved);
    } catch (_) {
      return Right(await _loadProfile());
    }
  }

  @override
  Future<Either<Failure, MemorizationProfile>>
  resetMemorizationIdentity() async {
    try {
      await _datasource.clearMemorizationProfile();
      await _datasource.clearPairingSession();
      await _datasource.clearSelectedTrack();
      await _datasource.clearIsParentMode();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.kHifzPathMode);
      return Right(await _loadProfile());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SmartMemorizationSettings>> getSmartSettings() async {
    try {
      return Right(await _datasource.getSmartSettings());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveSmartSettings(
    SmartMemorizationSettings settings,
  ) async {
    try {
      await _datasource.saveSmartSettings(
        SmartMemorizationSettingsModel.fromEntity(settings),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<MemorizationProfile> _loadProfile() async {
    final stored = await _datasource.getMemorizationProfile();
    if (stored.hasSelectedPath) return stored;

    final legacyTrack = _datasource.getSelectedTrack();
    final isParent = _datasource.getIsParentMode();
    final prefs = await SharedPreferences.getInstance();
    final legacyHifzPath = prefs.getString(AppConstants.kHifzPathMode);
    MemorizationPath? migratedPath;
    if (legacyTrack == MemorizationTrack.adults.name) {
      migratedPath = MemorizationPath.adult;
    } else if (legacyTrack == MemorizationTrack.kids.name) {
      migratedPath = MemorizationPath.child;
    }

    if (migratedPath == null && legacyHifzPath != null) {
      migratedPath = legacyHifzPath == 'backward'
          ? MemorizationPath.child
          : MemorizationPath.adult;
    }

    if (migratedPath == null && isParent) {
      migratedPath = MemorizationPath.adult;
    }

    if (migratedPath == null) return stored;
    final migrated = stored.copyWith(
      selectedPath: migratedPath,
      guardianLinkStatus: GuardianLinkStatus.none,
      guardianOnboardingStatus: migratedPath == MemorizationPath.child
          ? GuardianOnboardingStatus.skipped
          : GuardianOnboardingStatus.completed,
      isParentGuardian: migratedPath == MemorizationPath.adult && isParent,
    );
    return _saveProfile(migrated);
  }

  Future<MemorizationProfile> _saveProfile(MemorizationProfile profile) async {
    final model = MemorizationProfileModel.fromEntity(
      // UTC: consistent with review scheduling and streak date policy.
      profile.copyWith(updatedAt: DateTime.now().toUtc()),
    );
    await _datasource.saveMemorizationProfile(model);
    return model;
  }

  // ─── Track ──────────────────────────────────────────────────────────────────
  @override
  Either<Failure, MemorizationTrack?> getSelectedTrack() {
    try {
      final raw = _datasource.getSelectedTrack();
      if (raw == null) return const Right(null);
      final track = MemorizationTrack.values.firstWhere(
        (t) => t.name == raw,
        orElse: () => MemorizationTrack.adults,
      );
      return Right(track);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveSelectedTrack(
    MemorizationTrack track,
  ) async {
    try {
      final path = track == MemorizationTrack.kids
          ? MemorizationPath.child
          : MemorizationPath.adult;
      final result = await selectMemorizationPath(path);
      final failure = result.fold((failure) => failure, (_) => null);
      if (failure != null) return Left(failure);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  static const _retentionReviewLimit = 3;

  // ─── Daily plan ─────────────────────────────────────────────────────────────
  /// Builds today's plan and persists it to the local cache.
  ///
  /// Called directly for explicit refresh, and automatically from
  /// [getCachedDailyPlan] on the first access of each UTC day.
  @override
  Future<Either<Failure, DailyPlan>> generateDailyPlan({
    required int surahId,
    required int newAyahsPerDay,
  }) async {
    try {
      final allRecords = (await _datasource.getAllReviewRecords())
          .where(ReviewRecordFilters.isAdultCompatible)
          .toList();

      // BUG-7 FIX: Read custom plan settings and apply them
      final customPlan = await _datasource.getCustomPlan();
      final effectiveNewPerDay = customPlan?.newAyahsPerDay ?? newAyahsPerDay;
      final nearRevisionLimit = customPlan?.nearRevisionCount ?? 10;
      final farRevisionLimit = customPlan?.farRevisionCount ?? 5;

      // Direction-aware memorization:
      //   startSurahId = where memorization BEGINS  (the "من" surah)
      //   endSurahId   = where memorization ENDS    (the "إلى" surah)
      //
      //   If startSurahId <= endSurahId → ASCENDING  (e.g. Al-Fatiha 1 → An-Nas 114)
      //   If startSurahId >  endSurahId → DESCENDING (e.g. An-Nas 114 → An-Naba 78)
      final planStartSurahId = customPlan?.startSurahId ?? surahId;
      final planEndSurahId = customPlan?.endSurahId ?? planStartSurahId;
      final isDescending = planStartSurahId > planEndSurahId;

      // Honour a cached/caller surahId as a resume point if it lies within range.
      int currentSurahId = planStartSurahId;
      final lo = isDescending ? planEndSurahId : planStartSurahId;
      final hi = isDescending ? planStartSurahId : planEndSurahId;
      if (surahId >= lo && surahId <= hi && surahId != planStartSurahId) {
        currentSurahId = surahId;
      }

      DailyPlan? bestPlan;

      // Direction-aware loop
      while (isDescending
          ? currentSurahId >= planEndSurahId
          : currentSurahId <= planEndSurahId) {
        final surahRecords = {
          for (final r in allRecords.where((r) => r.surahId == currentSurahId))
            r.ayahNumber: r,
        };

        int totalAyahs = 7; // fallback
        List<Ayah> ayahs = [];
        final surahResult = await _quranRepository.getSurahDetail(
          currentSurahId,
        );
        surahResult.fold((_) {}, (detail) {
          totalAyahs = detail.surah.ayahCount;
          ayahs = detail.ayahs;
        });

        final List<DailyPlanAyah> newAyahs = [];
        final List<DailyPlanAyah> nearRevision = [];
        final List<DailyPlanAyah> farRevision = [];
        final List<DailyPlanAyah> retentionReview = [];

        // startAyah applies only to the first surah in the memorization order
        // (i.e. startSurahId itself), not to any other surah in the range.
        final firstAyah =
            customPlan != null && currentSurahId == customPlan.startSurahId
            ? customPlan.startAyah.clamp(1, totalAyahs)
            : 1;

        for (int i = firstAyah; i <= totalAyahs; i++) {
          final record = surahRecords[i];

          String ayahText = 'النص غير متوفر';
          try {
            ayahText = ayahs.firstWhere((a) => a.numberInSurah == i).text;
          } catch (_) {}

          if (record == null || record.isNew) {
            if (newAyahs.length < effectiveNewPerDay) {
              newAyahs.add(
                DailyPlanAyah(
                  surahId: currentSurahId,
                  ayahNumber: i,
                  ayahText: ayahText,
                  record: record,
                ),
              );
            }
          } else {
            final classification = record.reviewClassification;
            if (!classification.isDue) continue;
            final planAyah = DailyPlanAyah(
              surahId: currentSurahId,
              ayahNumber: i,
              ayahText: ayahText,
              record: record,
            );
            // BUG-7 FIX: apply custom plan revision limits
            if (customPlan?.enableNearRevision != false &&
                classification.isNearRevision &&
                nearRevision.length < nearRevisionLimit) {
              nearRevision.add(planAyah);
            } else if (customPlan?.enableFarRevision != false &&
                classification.isFarRevision &&
                farRevision.length < farRevisionLimit) {
              farRevision.add(planAyah);
            }
          }
        }

        final retentionCandidates =
            surahRecords.values
                .where(ReviewRecordFilters.isDailyPlanRetentionEligible)
                .toList()
              ..sort(ReviewRecordFilters.compareMemorizedDue);
        for (final record in retentionCandidates.take(_retentionReviewLimit)) {
          String ayahText = 'النص غير متوفر';
          try {
            ayahText = ayahs
                .firstWhere((a) => a.numberInSurah == record.ayahNumber)
                .text;
          } catch (_) {}
          retentionReview.add(
            DailyPlanAyah(
              surahId: currentSurahId,
              ayahNumber: record.ayahNumber,
              ayahText: ayahText,
              record: record,
            ),
          );
        }

        bestPlan = DailyPlan(
          // UTC so the same-day stale check in getCachedDailyPlan is timezone-safe.
          generatedAt: DateTime.now().toUtc(),
          surahId: currentSurahId,
          newAyahs: newAyahs,
          nearRevision: nearRevision,
          farRevision: farRevision,
          completedAyahNums: const [],
          retentionReview: retentionReview,
        );

        if (bestPlan.totalItems > 0 || bestPlan.hasRetentionReview) {
          break;
        }

        // Advance in the memorization direction
        if (isDescending) {
          currentSurahId--;
        } else {
          currentSurahId++;
        }
      }

      bestPlan ??= DailyPlan(
        generatedAt: DateTime.now().toUtc(),
        surahId: planEndSurahId,
        newAyahs: const [],
        nearRevision: const [],
        farRevision: const [],
        completedAyahNums: const [],
        retentionReview: const [],
      );

      // Cache the plan
      await _datasource.saveDailyPlan(DailyPlanModel.fromEntity(bestPlan));

      return Right(bestPlan);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async {
    try {
      final cached = await _datasource.getCachedDailyPlan();
      final now = DateTime.now().toUtc();
      if (cached != null && _isSameUtcDay(cached.generatedAt, now)) {
        return Right(cached);
      }

      // First access of the day (or missing cache): regenerate for active adult plans.
      final customPlan = await _datasource.getCustomPlan();
      final hasActiveAdultPlan =
          customPlan != null &&
          customPlan.isActive &&
          customPlan.targetUser == PlanTargetUser.adult;
      if (!hasActiveAdultPlan) {
        return const Right(null);
      }

      final resumeSurahId = cached?.surahId;
      final surahId =
          resumeSurahId != null &&
              _isSurahInCustomPlanRange(resumeSurahId, customPlan)
          ? resumeSurahId
          : customPlan.startSurahId;

      final generated = await generateDailyPlan(
        surahId: surahId,
        newAyahsPerDay: customPlan.newAyahsPerDay,
      );
      return generated.map((plan) => plan);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  bool _isSameUtcDay(DateTime a, DateTime b) {
    final au = a.toUtc();
    final bu = b.toUtc();
    return au.year == bu.year && au.month == bu.month && au.day == bu.day;
  }

  bool _isSurahInCustomPlanRange(int surahId, CustomMemorizationPlan plan) {
    final lo = plan.startSurahId <= plan.endSurahId
        ? plan.startSurahId
        : plan.endSurahId;
    final hi = plan.startSurahId <= plan.endSurahId
        ? plan.endSurahId
        : plan.startSurahId;
    return surahId >= lo && surahId <= hi;
  }

  @override
  Future<Either<Failure, void>> saveDailyPlan(DailyPlan plan) async {
    try {
      await _datasource.saveDailyPlan(DailyPlanModel.fromEntity(plan));
      await _prefs.setBool(_dailyPlanCloudDirtyKey, true);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> markDailyPlanAyahCompleted({
    required int surahId,
    required int ayahNumber,
  }) async {
    try {
      final cachedResult = await getCachedDailyPlan();
      return cachedResult.fold<Future<Either<Failure, bool>>>(
        (failure) async => Left(failure),
        (plan) async {
          if (plan == null || plan.surahId != surahId) {
            return const Right(false);
          }
          if (plan.isCompleted(ayahNumber)) return const Right(false);

          final inRequired = plan.requiredAyahs.any(
            (ayah) => ayah.ayahNumber == ayahNumber,
          );
          final inRetention = plan.retentionReview.any(
            (ayah) => ayah.ayahNumber == ayahNumber,
          );
          if (!inRequired && !inRetention) return const Right(false);

          final saveResult = await saveDailyPlan(
            plan.withCompleted(ayahNumber),
          );
          return saveResult.fold(Left.new, (_) {
            _progressEvents.notify(ProgressChangedReason.dailyPlan);
            return const Right(true);
          });
        },
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Review records ─────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, AyahReviewRecord?>> getReviewRecord(
    int surahId,
    int ayahNumber, {
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async {
    try {
      final record = await _datasource.getReviewRecord(
        surahId,
        ayahNumber,
        scope: scope,
      );
      return Right(record);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async {
    try {
      final records = await _datasource.getAllReviewRecords(scope: scope);
      return Right(records);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveReviewRecord(
    AyahReviewRecord record,
  ) async {
    try {
      await _datasource.saveReviewRecord(
        AyahReviewRecordModel.fromEntity(record),
      );
      // Delta sync: mark dirty locally; [resyncProductionDataToCloud] uploads.
      _progressEvents.notify(ProgressChangedReason.reviewRecord);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Kids progress ───────────────────────────────────────────────────────────

  /// Overlays [KidsProgress.currentStreak] from [StreakService] (single SSOT).
  Future<KidsProgress> _hydrateKidsStreak(KidsProgress progress) async {
    final streak = await _streakReader.getStreak();
    return progress.copyWith(currentStreak: streak.currentStreak);
  }

  /// Persists kids prefs without a local streak counter (streak lives in Isar).
  KidsProgress _kidsProgressForStorage(KidsProgress progress) =>
      progress.copyWith(currentStreak: 0);

  @override
  Future<Either<Failure, KidsProgress>> getKidsProgress() async {
    try {
      final progress = await _datasource.getKidsProgress();
      return Right(await _hydrateKidsStreak(progress));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveKidsProgress(KidsProgress progress) async {
    try {
      await _datasource.saveKidsProgress(
        KidsProgressModel.fromEntity(_kidsProgressForStorage(progress)),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Kids journey "needs review" when a completed stage has weak or overdue SRS.
  static bool _ayahNeedsKidsReview(AyahReviewRecord record) =>
      record.isDue || record.lastRating == PerformanceRating.weak;

  static bool _stageNeedsKidsReview({
    required int surahId,
    required List<int> ayahRange,
    required Map<String, AyahReviewRecord> kidsRecordsByKey,
  }) {
    for (final ayah in ayahRange) {
      final record = kidsRecordsByKey['${surahId}_$ayah'];
      if (record != null && _ayahNeedsKidsReview(record)) return true;
    }
    return false;
  }

  @override
  Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
    required int surahId,
  }) async {
    try {
      final logs = await _datasource.getKidsSessionLogs();
      final completed = logs
          .where((log) => log.surahId == surahId)
          .map((log) => log.ayahNumber)
          .toSet();

      final kidsRecords = await _datasource.getAllReviewRecords(
        scope: ReviewRecordReadScope.kids,
      );
      final kidsRecordsByKey = {
        for (final record in kidsRecords.where(
          (r) => r.surahId == surahId && ReviewRecordFilters.isKidsSource(r),
        ))
          record.key: record,
      };

      var totalAyahs = 7;
      final detailResult = await _quranRepository.getSurahDetail(surahId);
      detailResult.fold(
        (_) {},
        (detail) => totalAyahs = detail.surah.ayahCount,
      );

      const stageSize = 5;
      final stages = <KidsJourneyStage>[];
      var foundCurrent = false;
      for (var start = 1; start <= totalAyahs; start += stageSize) {
        final end = min(start + stageSize - 1, totalAyahs);
        final ayahRange = List<int>.generate(end - start + 1, (i) => start + i);
        final stageCompleted = ayahRange
            .where((ayah) => completed.contains(ayah))
            .toList();

        KidsJourneyStageStatus status;
        if (stageCompleted.length == ayahRange.length) {
          status =
              _stageNeedsKidsReview(
                surahId: surahId,
                ayahRange: ayahRange,
                kidsRecordsByKey: kidsRecordsByKey,
              )
              ? KidsJourneyStageStatus.needsReview
              : KidsJourneyStageStatus.completed;
        } else if (!foundCurrent) {
          status = KidsJourneyStageStatus.current;
          foundCurrent = true;
        } else {
          status = KidsJourneyStageStatus.locked;
        }

        stages.add(
          KidsJourneyStage(
            stageNumber: stages.length + 1,
            surahId: surahId,
            startAyah: start,
            endAyah: end,
            completedAyahs: stageCompleted,
            status: status,
          ),
        );
      }
      return Right(stages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async {
    try {
      return Right(await _datasource.getKidsSessionLogs());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, KidsSessionLog>> saveKidsSessionLog({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    required int pointsEarned,
  }) async {
    try {
      final logs = await _datasource.getKidsSessionLogs();
      KidsSessionLogModel? existing;
      for (final log in logs) {
        if (log.surahId == surahId && log.ayahNumber == ayahNumber) {
          existing = log;
          break;
        }
      }
      if (existing != null) return Right(existing);

      // UTC: consistent with all other review/session date fields.
      final now = DateTime.now().toUtc();
      final log = KidsSessionLogModel(
        id: '${now.microsecondsSinceEpoch}_${surahId}_$ayahNumber',
        surahId: surahId,
        ayahNumber: ayahNumber,
        repeatsCompleted: repeatsCompleted,
        pointsEarned: pointsEarned,
        completedAt: now,
      );
      await _datasource.saveKidsSessionLog(log);
      await _unlockWeeklyRewardIfNeeded();
      unawaited(syncKidsProgressToCloud());
      _progressEvents.notify(ProgressChangedReason.kidsProgress);
      return Right(log);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParentDashboard>> getParentDashboard({
    required int surahId,
  }) async {
    try {
      final progressResult = await getKidsProgress();
      final progress = progressResult.getOrElse(
        () => throw StateError('Expected kids progress'),
      );
      final logs = await _datasource.getKidsSessionLogs();
      final settings = await _datasource.getParentSettings();
      final rewards = await _datasource.getParentRewards();
      final journey = await getKidsJourney(surahId: surahId);
      return journey.fold(
        Left.new,
        (stages) => Right(
          ParentDashboard(
            progress: progress,
            stages: stages,
            logs: logs,
            rewards: rewards,
            settings: settings,
          ),
        ),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParentSettings>> getParentSettings() async {
    try {
      return Right(await _datasource.getParentSettings());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveParentSettings(
    ParentSettings settings,
  ) async {
    try {
      await _datasource.saveParentSettings(
        ParentSettingsModel.fromEntity(settings),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyParentPin(String pin) async {
    try {
      final settings = await _datasource.getParentSettings();
      final stored = settings.pinHash;
      if (stored == _hashPin(pin)) {
        return const Right(true);
      }

      if (_isLegacyPlaintextPin(stored) && stored == pin) {
        await _datasource.saveParentSettings(
          ParentSettingsModel.fromEntity(
            settings.copyWith(pinHash: _hashPin(pin)),
          ),
        );
        return const Right(true);
      }

      return const Right(false);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setParentPin(String pin) async {
    try {
      final settings = await _datasource.getParentSettings();
      await _datasource.saveParentSettings(
        ParentSettingsModel.fromEntity(
          settings.copyWith(pinHash: _hashPin(pin)),
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetParentAccess() async {
    try {
      final settings = await _datasource.getParentSettings();
      await _datasource.saveParentSettings(
        ParentSettingsModel.fromEntity(
          settings.copyWith(clearPin: true, remoteLinkEnabled: false),
        ),
      );
      await _datasource.saveParentRewards(const []);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParentReward>>> saveParentReward(
    String title,
  ) async {
    try {
      final trimmed = title.trim();
      if (trimmed.isEmpty) {
        return const Left(CacheFailure('اكتب اسم المكافأة أولاً'));
      }
      final rewards = await _datasource.getParentRewards();
      if (rewards.length >= 3) {
        return const Left(CacheFailure('يمكن إضافة 3 مكافآت فقط'));
      }
      final reward = ParentRewardModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: trimmed,
        status: ParentRewardStatus.locked,
        createdAt: DateTime.now(),
      );
      final next = [...rewards, reward];
      await _datasource.saveParentRewards(next);
      return Right(next);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParentReward>>> claimParentReward(
    String id,
  ) async {
    try {
      final rewards = await _datasource.getParentRewards();
      final next = rewards
          .map(
            (reward) => reward.id == id
                ? ParentRewardModel.fromEntity(
                    reward.copyWith(
                      status: ParentRewardStatus.claimed,
                      claimedAt: DateTime.now(),
                    ),
                  )
                : reward,
          )
          .toList();
      await _datasource.saveParentRewards(next);
      return Right(next);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createChildLinkToken() async {
    try {
      final clientResult = _supabaseOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      if (client.auth.currentUser == null) {
        return const Left(
          NetworkFailure('Guardian linking requires signing in first'),
        );
      }

      // Generate random 12-char uppercase hex token (no pgcrypto needed)
      final rng = Random.secure();
      final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
      final token = bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .substring(0, 12)
          .toUpperCase();

      // Hash the token with SHA-256 (matches what the DB used to do)
      final tokenHash = sha256.convert(utf8.encode(token)).toString();

      await client.rpc(
        'create_child_link_request_with_hash',
        params: {'p_token_hash': tokenHash},
      );

      return Right(token);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptChildLinkToken(String token) async {
    try {
      final clientResult = _supabaseOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      if (client.auth.currentUser == null) {
        return const Left(
          NetworkFailure('سجّل الدخول أولاً على جهاز ولي الأمر'),
        );
      }
      // Hash the token client-side (no pgcrypto needed)
      final rawToken = _extractToken(token).toUpperCase().trim();
      final tokenHash = sha256.convert(utf8.encode(rawToken)).toString();
      await client.rpc(
        'accept_child_link_token_with_hash',
        params: {'p_token_hash': tokenHash},
      );
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncKidsProgressToCloud() async {
    try {
      final clientResult = _supabaseOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      final user = client.auth.currentUser;
      if (user == null) return const Right(null);

      final progress = await _datasource.getKidsProgress();
      final streak = await _streakReader.getStreak();
      await client.rpc(
        'upsert_kids_progress_cloud',
        params: {
          'p_total_points': progress.totalPoints,
          'p_current_level': progress.currentLevel,
          'p_current_streak': streak.currentStreak,
          'p_stars_earned': progress.starsEarned,
          'p_ayahs_completed': progress.ayahsCompleted,
          'p_last_session_at': progress.lastSessionAt
              ?.toUtc()
              .toIso8601String(),
        },
      );

      final logs = await _datasource.getKidsSessionLogs();
      final pendingLogs = logs.where((log) => !log.isSynced).toList();
      if (pendingLogs.isNotEmpty) {
        await _pushKidsSessionLogs(client, pendingLogs);
      }

      final updatedLogs = logs
          .map(
            (log) => log.isSynced
                ? log
                : KidsSessionLogModel.fromEntity(
                    log.copyWith(syncedAt: DateTime.now().toUtc()),
                  ),
          )
          .toList();
      await _datasource.saveKidsSessionLogs(updatedLogs);
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RemoteChildSummary>>> getRemoteChildren() async {
    try {
      final clientResult = _supabaseOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      final user = client.auth.currentUser;
      if (user == null) {
        return const Left(NetworkFailure('سجّل الدخول أولاً'));
      }

      try {
        final payload = await client.rpc('get_remote_children_dashboard');
        return Right(_parseRemoteChildrenDashboard(payload));
      } on PostgrestException catch (e) {
        if (!_isMissingRpc(e, 'get_remote_children_dashboard')) rethrow;
      }

      return Right(await _fetchRemoteChildrenLegacy(client, user.id));
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  List<RemoteChildSummary> _parseRemoteChildrenDashboard(dynamic raw) {
    final items = raw as List<dynamic>? ?? const [];
    return items
        .map(
          (item) => _remoteChildSummaryFromDashboardJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  RemoteChildSummary _remoteChildSummaryFromDashboardJson(
    Map<String, dynamic> row,
  ) {
    final childId = row['child_user_id'] as String;
    final progressRaw = row['progress'];
    final logsRaw = row['logs'] as List<dynamic>? ?? const [];
    final rewardsRaw = row['rewards'] as List<dynamic>? ?? const [];

    RemoteChildProductionSummary? production;
    try {
      final reviewRows = (row['review_rows'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final dailyPlanRaw = row['daily_plan'];
      final dailyPlanRow = dailyPlanRaw == null
          ? null
          : Map<String, dynamic>.from(dailyPlanRaw as Map);
      final certRows = (row['certificates'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final streakRaw = row['streak'];
      final streakRow = streakRaw == null
          ? null
          : Map<String, dynamic>.from(streakRaw as Map);
      final activityRows = (row['activities'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      production = _buildProductionSummary(
        reviewRows: reviewRows,
        dailyPlanRow: dailyPlanRow,
        certRows: certRows,
        streakRow: streakRow,
        activityRows: activityRows,
      );
    } catch (_) {
      production = null;
    }

    return RemoteChildSummary(
      childUserId: childId,
      displayName: row['display_name'] as String? ?? 'طفل تالية',
      progress: _progressFromCloud(
        progressRaw == null ? null : Map<String, dynamic>.from(progressRaw as Map),
      ),
      logs: logsRaw
          .map((item) => _logFromCloud(Map<String, dynamic>.from(item as Map)))
          .toList(),
      rewards: rewardsRaw
          .map(
            (item) => _rewardFromCloud(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      production: production,
    );
  }

  Future<List<RemoteChildSummary>> _fetchRemoteChildrenLegacy(
    SupabaseClient client,
    String parentUserId,
  ) async {
    final links = await client
        .from('parent_child_links')
        .select('child_user_id')
        .eq('parent_user_id', parentUserId)
        .eq('status', 'active');

    final children = <RemoteChildSummary>[];
    for (final link in links) {
      final childId = link['child_user_id'] as String;
      final profileRows = await client
          .from('profiles')
          .select('display_name')
          .eq('id', childId)
          .limit(1);
      final progressRows = await client
          .from('kids_progress_cloud')
          .select()
          .eq('child_user_id', childId)
          .limit(1);
      final logRows = await client
          .from('kids_session_logs')
          .select()
          .eq('child_user_id', childId)
          .order('completed_at', ascending: false)
          .limit(30);
      final rewardRows = await client
          .from('parent_rewards')
          .select()
          .eq('child_user_id', childId)
          .order('created_at', ascending: false);

      RemoteChildProductionSummary? production;
      try {
        final reviewRows = await client
            .from('ayah_review_records_cloud')
            .select()
            .eq('user_id', childId);
        final dailyPlanRows = await client
            .from('daily_plans_cloud')
            .select()
            .eq('user_id', childId)
            .limit(1);
        final certRows = await client
            .from('certificate_awards_cloud')
            .select()
            .eq('user_id', childId)
            .order('earned_at', ascending: false);
        final streakRows = await client
            .from('streaks')
            .select()
            .eq('user_id', childId)
            .limit(1);
        final activityRows = await client
            .from('daily_activities')
            .select('day_key, activity_count')
            .eq('user_id', childId)
            .order('day_key', ascending: false)
            .limit(31);

        production = _buildProductionSummary(
          reviewRows: List<Map<String, dynamic>>.from(reviewRows),
          dailyPlanRow: dailyPlanRows.isEmpty ? null : dailyPlanRows.first,
          certRows: List<Map<String, dynamic>>.from(certRows),
          streakRow: streakRows.isEmpty ? null : streakRows.first,
          activityRows: List<Map<String, dynamic>>.from(activityRows),
        );
      } catch (_) {
        production = null;
      }

      children.add(
        RemoteChildSummary(
          childUserId: childId,
          displayName: profileRows.isEmpty
              ? 'طفل تالية'
              : profileRows.first['display_name'] as String? ?? 'طفل تالية',
          progress: _progressFromCloud(
            progressRows.isEmpty ? null : progressRows.first,
          ),
          logs: logRows.map(_logFromCloud).toList(),
          rewards: rewardRows.map(_rewardFromCloud).toList(),
          production: production,
        ),
      );
    }
    return children;
  }

  bool _isMissingRpc(PostgrestException error, String rpcName) {
    final message = error.message.toLowerCase();
    return message.contains(rpcName.toLowerCase()) ||
        message.contains('could not find the function');
  }

  @override
  Future<Either<Failure, List<ParentReward>>> saveRemoteParentReward({
    required String childUserId,
    required String title,
  }) async {
    try {
      final trimmed = title.trim();
      if (trimmed.isEmpty) {
        return const Left(CacheFailure('اكتب اسم المكافأة أولاً'));
      }
      final clientResult = _supabaseOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      final user = client.auth.currentUser;
      if (user == null) {
        return const Left(NetworkFailure('سجّل الدخول أولاً'));
      }
      await client.from('parent_rewards').insert({
        'parent_user_id': user.id,
        'child_user_id': childUserId,
        'title': trimmed,
      });
      final rows = await client
          .from('parent_rewards')
          .select()
          .eq('child_user_id', childUserId)
          .order('created_at', ascending: false);
      return Right(rows.map(_rewardFromCloud).toList());
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, KidsCompletionResult>> awardKidsPoints({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
  }) => _withKidsAwardLock(surahId, ayahNumber, () async {
    try {
      final current = await _datasource.getKidsProgress();
      final logs = await _datasource.getKidsSessionLogs();
      final alreadyCompleted = logs.any(
        (log) => log.surahId == surahId && log.ayahNumber == ayahNumber,
      );
      if (alreadyCompleted) {
        return Right(
          KidsCompletionResult(
            progress: await _hydrateKidsStreak(current),
            pointsEarned: 0,
            starsEarned: 0,
            alreadyCompleted: true,
          ),
        );
      }

      // Points: 10 base + 2 per extra repeat
      final points = 10 + ((repeatsCompleted - 1) * 2).clamp(0, 20);
      final updated = current.addPoints(points);
      await _datasource.saveKidsProgress(
        KidsProgressModel.fromEntity(_kidsProgressForStorage(updated)),
      );
      final logResult = await saveKidsSessionLog(
        surahId: surahId,
        ayahNumber: ayahNumber,
        repeatsCompleted: repeatsCompleted,
        pointsEarned: points,
      );
      final logFailure = logResult.fold((failure) => failure, (_) => null);
      if (logFailure != null) return Left(logFailure);

      return Right(
        KidsCompletionResult(
          progress: await _hydrateKidsStreak(updated),
          pointsEarned: points,
          starsEarned: updated.starsEarned - current.starsEarned,
          alreadyCompleted: false,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  });

  Future<T> _withKidsAwardLock<T>(
    int surahId,
    int ayahNumber,
    Future<T> Function() action,
  ) async {
    final key = '${surahId}_$ayahNumber';
    final previous = _kidsAwardLocks[key];
    final completer = Completer<void>();
    final current = previous == null
        ? completer.future
        : previous.catchError((_) {}).then((_) => completer.future);
    _kidsAwardLocks[key] = current;

    if (previous != null) {
      try {
        await previous;
      } catch (_) {}
    }

    try {
      return await action();
    } finally {
      completer.complete();
      if (_kidsAwardLocks[key] == current) {
        unawaited(_kidsAwardLocks.remove(key));
      }
    }
  }

  String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  bool _isLegacyPlaintextPin(String? value) {
    return value != null && value.length == 4 && int.tryParse(value) != null;
  }

  String _extractToken(String raw) {
    const prefix = 'talia-kids-link:';
    final trimmed = raw.trim();
    return trimmed.toLowerCase().startsWith(prefix)
        ? trimmed.substring(prefix.length)
        : trimmed;
  }

  Future<String?> _activeGuardianIdForChild(String childUserId) async {
    final links = await _supabase
        .from('parent_child_links')
        .select('parent_user_id')
        .eq('child_user_id', childUserId)
        .eq('status', 'active')
        .order('linked_at', ascending: false)
        .limit(1);
    if (links.isEmpty) return null;
    return links.first['parent_user_id'] as String?;
  }

  Future<String?> _latestActiveChildIdForParent(String parentUserId) async {
    final links = await _supabase
        .from('parent_child_links')
        .select('child_user_id')
        .eq('parent_user_id', parentUserId)
        .eq('status', 'active')
        .order('linked_at', ascending: false)
        .limit(1);
    if (links.isEmpty) return null;
    return links.first['child_user_id'] as String?;
  }

  Future<void> _unlockWeeklyRewardIfNeeded() async {
    final logs = await _datasource.getKidsSessionLogs();
    final settings = await _datasource.getParentSettings();
    final rewards = await _datasource.getParentRewards();
    if (rewards.isEmpty ||
        rewards.every((r) => r.status != ParentRewardStatus.locked)) {
      return;
    }
    // P1-06 FIX: Use UTC to match completedAt (stored as UTC at line ~883).
    // Mixing local weekStart with UTC logs shifted week boundaries by the
    // timezone offset (e.g. UTC+3 in Egypt).
    final now = DateTime.now().toUtc();
    final weekStart = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final sessionsThisWeek = logs
        .where((log) => !log.completedAt.isBefore(weekStart))
        .length;
    if (sessionsThisWeek < settings.weeklyGoalSessions) return;

    var unlockedOne = false;
    final next = rewards.map((reward) {
      if (!unlockedOne && reward.status == ParentRewardStatus.locked) {
        unlockedOne = true;
        return ParentRewardModel.fromEntity(
          reward.copyWith(
            status: ParentRewardStatus.unlocked,
            unlockedAt: DateTime.now().toUtc(),
          ),
        );
      }
      return reward;
    }).toList();
    await _datasource.saveParentRewards(next);
  }

  KidsProgress _progressFromCloud(Map<String, dynamic>? row) {
    if (row == null) return const KidsProgress.initial();
    return KidsProgress(
      totalPoints: row['total_points'] as int? ?? 0,
      currentLevel: row['current_level'] as int? ?? 1,
      currentStreak: row['current_streak'] as int? ?? 0,
      starsEarned: row['stars_earned'] as int? ?? 0,
      ayahsCompleted: row['ayahs_completed'] as int? ?? 0,
      lastSessionAt: row['last_session_at'] == null
          ? null
          : DateTime.parse(row['last_session_at'] as String),
    );
  }

  KidsSessionLog _logFromCloud(Map<String, dynamic> row) => KidsSessionLog(
    id: row['local_id'] as String? ?? row['id'].toString(),
    surahId: row['surah_id'] as int,
    ayahNumber: row['ayah_number'] as int,
    repeatsCompleted: row['repeats_completed'] as int? ?? 0,
    pointsEarned: row['points_earned'] as int? ?? 0,
    completedAt: DateTime.parse(row['completed_at'] as String),
    syncedAt: DateTime.now(),
  );

  ParentReward _rewardFromCloud(Map<String, dynamic> row) => ParentReward(
    id: row['id'].toString(),
    title: row['title'] as String,
    status: ParentRewardStatus.values.firstWhere(
      (status) => status.name == (row['status'] as String? ?? 'locked'),
      orElse: () => ParentRewardStatus.locked,
    ),
    createdAt: DateTime.parse(row['created_at'] as String),
    unlockedAt: row['unlocked_at'] == null
        ? null
        : DateTime.parse(row['unlocked_at'] as String),
    claimedAt: row['claimed_at'] == null
        ? null
        : DateTime.parse(row['claimed_at'] as String),
  );

  // ─── Custom memorization plan ──────────────────────────────────────────────

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async {
    try {
      final plan = await _datasource.getCustomPlan();
      return Right(plan);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveCustomPlan(
    CustomMemorizationPlan plan,
  ) async {
    try {
      await _datasource.saveCustomPlan(
        CustomMemorizationPlanModel.fromEntity(plan),
      );
      // Clear the cached daily plan so that a stale surahId from a previous
      // session does not override the correct entry point (endSurahId) when
      // the user returns to the app after saving a new plan.
      try {
        await _datasource.clearDailyPlanCache();
      } catch (_) {
        // Non-critical: cache clearing failure should not block plan saving.
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomPlan() async {
    try {
      await _datasource.deleteCustomPlan();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Parent mode toggle ──────────────────────────────────────────────────
  // T015: Read through MemorizationProfile so the value is always the single
  // source of truth, not the raw legacy SharedPreferences flag.
  @override
  Either<Failure, bool> getIsParentMode() {
    try {
      // Synchronous fast-path: check the cached datasource profile first.
      // The profile is always written by _saveProfile which keeps the legacy
      // flag in sync, so this is safe and avoids an async round-trip.
      return Right(_datasource.getIsParentMode());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Async variant that reads the authoritative MemorizationProfile.
  /// Prefer this over [getIsParentMode] wherever async is acceptable.
  Future<Either<Failure, bool>> getIsParentModeFromProfile() async {
    try {
      final profile = await _loadProfile();
      return Right(profile.isParentGuardian);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setIsParentMode(bool value) async {
    try {
      final result = await setParentGuardianMode(value);
      return result.fold(Left.new, (_) => const Right(null));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Phase 7: Production sync (Parent Mode completion) ─────────────────────

  bool _isProductionReviewRecord(AyahReviewRecord record) =>
      record.createdByMode == ReviewRecordCreatedByMode.v2Session ||
      record.createdByMode == ReviewRecordCreatedByMode.kidsMode ||
      record.createdByMode == ReviewRecordCreatedByMode.hifz;

  @override
  Future<Either<Failure, void>> pullProductionDataFromCloud() async {
    try {
      if (!_isSupabaseReady || !_cloudPullEnabled) return const Right(null);
      final client = _supabase;
      final user = client.auth.currentUser;
      if (user == null) return const Right(null);

      final rows = await client.rpc('pull_ayah_review_records');
      final cloudRows = (rows as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();

      for (final row in cloudRows) {
        final cloudRecord = _reviewRecordFromCloud(row);
        if (!_isProductionReviewRecord(cloudRecord)) continue;

        final readScope = ReviewRecordAudienceScope.scopeForWriteMode(
          cloudRecord.createdByMode,
        );
        final localModel = await _datasource.getReviewRecord(
          cloudRecord.surahId,
          cloudRecord.ayahNumber,
          scope: readScope,
        );
        final merged = ReviewRecordCloudMerge.merge(
          local: localModel,
          remote: cloudRecord,
        );
        final mergedModel = AyahReviewRecordModel.fromEntity(merged);
        if (localModel == null || localModel != mergedModel) {
          await _datasource.saveReviewRecord(
            mergedModel,
            markCloudDirty: false,
          );
        }
      }

      await _mergeDailyPlanFromCloud(client, user.id);
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  Future<bool> _mergeDailyPlanFromCloud(
    SupabaseClient client,
    String userId,
  ) async {
    final rows = await client
        .from('daily_plans_cloud')
        .select()
        .eq('user_id', userId);
    if (rows.isEmpty) return false;

    final row = rows.first;
    final cloudGeneratedAt = DateTime.parse(row['generated_at'] as String);
    final local = await _datasource.getCachedDailyPlan();
    if (local != null && !cloudGeneratedAt.isAfter(local.generatedAt.toUtc())) {
      return false;
    }

    final payload = row['payload'];
    if (payload is! Map<String, dynamic>) return false;

    try {
      await _datasource.saveDailyPlan(DailyPlanModel.fromJson(payload));
      await _prefs.setBool(_dailyPlanCloudDirtyKey, false);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Either<Failure, void>> resyncProductionDataToCloud() async {
    try {
      if (!_isSupabaseReady) return const Right(null);
      final client = _supabase;
      final user = client.auth.currentUser;
      if (user == null) return const Right(null);

      final dirtyRecords = await _datasource.getCloudDirtyReviewRecords(
        includeAllAudiences: true,
      );
      final productionRecords = dirtyRecords
          .where(_isProductionReviewRecord)
          .toList();
      if (productionRecords.isNotEmpty) {
        await _pushReviewRecordsBatch(client, productionRecords);
        await _datasource.markReviewRecordsCloudSynced(
          productionRecords.map(_reviewRecordStorageKey),
        );
      }

      if (_prefs.getBool(_dailyPlanCloudDirtyKey) ?? false) {
        final cachedPlan = await _datasource.getCachedDailyPlan();
        if (cachedPlan != null) {
          await _upsertDailyPlanRow(client, user.id, cachedPlan);
          await _prefs.setBool(_dailyPlanCloudDirtyKey, false);
        }
      }

      return const Right(null);
    } catch (e) {
      // Best-effort resync: local state remains authoritative. The next
      // resume/login retry will pick up anything that failed here.
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> pushCertificatesToCloud(
    List<CertificateAward> certificates,
  ) async {
    if (certificates.isEmpty) return const Right(null);
    try {
      if (!_isSupabaseReady) return const Right(null);
      final client = _supabase;
      final user = client.auth.currentUser;
      if (user == null) return const Right(null);

      final rows = certificates
          .map(
            (c) => {
              'user_id': user.id,
              'cert_id': c.id,
              'title_ar': c.titleAr,
              'cert_type': c.type.name,
              'earned_at': c.earnedAt.toUtc().toIso8601String(),
            },
          )
          .toList();

      // ignoreDuplicates → ON CONFLICT DO NOTHING: certificates are
      // immutable once earned, and the RLS policy only grants INSERT+SELECT.
      await client
          .from('certificate_awards_cloud')
          .upsert(rows, onConflict: 'user_id,cert_id', ignoreDuplicates: true);
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> revokeGuardianLink(
    String counterpartUserId,
  ) async {
    try {
      final clientResult = _supabaseOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      if (client.auth.currentUser == null) {
        return const Left(NetworkFailure('سجّل الدخول أولاً'));
      }

      await client.rpc(
        'revoke_guardian_link',
        params: {'p_counterpart_user_id': counterpartUserId},
      );
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeChild(String childUserId) =>
      revokeGuardianLink(childUserId);

  @override
  Future<Either<Failure, FamilyDashboard>> getFamilyDashboard() async {
    try {
      final settings = await _datasource.getParentSettings();
      final children = <FamilyChildEntry>[];

      // ─── 1. Local child (same device) ────────────────────────────────────
      // Only shown when this device is configured as a parent-guardian device.
      final profile = await _loadProfile();
      if (profile.isParentGuardian) {
        final progressResult = await getKidsProgress();
        final progress = progressResult.getOrElse(
          () => const KidsProgress.initial(),
        );
        final logs = await _datasource.getKidsSessionLogs();
        final rewards = await _datasource.getParentRewards();
        final localChildId = profile.linkedChildId ?? 'local-child';
        final localDashboard = ParentDashboard(
          progress: progress,
          stages: const [],
          logs: logs,
          rewards: rewards,
          settings: settings,
        );
        children.add(
          FamilyChildEntry(
            childUserId: localChildId,
            displayName: settings.localChildNickname ?? 'طفلي',
            isLocal: true,
            localData: localDashboard,
          ),
        );
      }

      // ─── 2. Remote children (Supabase) ────────────────────────────────────
      final remoteResult = await getRemoteChildren();
      remoteResult.fold(
        (_) {}, // silently ignore remote errors; show local child if any
        (remoteChildren) {
          for (final r in remoteChildren) {
            // Avoid duplicate if remote child === local child
            final alreadyAdded =
                children.any((c) => c.childUserId == r.childUserId);
            if (!alreadyAdded) {
              children.add(
                FamilyChildEntry(
                  childUserId: r.childUserId,
                  displayName: r.displayName,
                  isLocal: false,
                  remoteSummary: r,
                ),
              );
            }
          }
        },
      );

      return Right(
        FamilyDashboard(children: children, settings: settings),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  String _reviewRecordStorageKey(AyahReviewRecord record) =>
      ReviewRecordAudienceScope.storageKey(
        surahId: record.surahId,
        ayahNumber: record.ayahNumber,
        mode: record.createdByMode,
        scoped: ReviewRecordAudienceScope.isEnabled(
          readBool: (key) => _prefs.getBool(key) ?? false,
        ),
      );

  Future<void> _pushKidsSessionLogs(
    SupabaseClient client,
    List<KidsSessionLog> logs,
  ) async {
    if (logs.isEmpty) return;

    final payload = logs
        .map(
          (log) => {
            'local_id': log.id,
            'surah_id': log.surahId,
            'ayah_number': log.ayahNumber,
            'repeats_completed': log.repeatsCompleted,
            'points_earned': log.pointsEarned,
            'completed_at': log.completedAt.toUtc().toIso8601String(),
          },
        )
        .toList();

    try {
      await client.rpc(
        'insert_kids_session_logs_batch',
        params: {'p_data': payload},
      );
      return;
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (!message.contains('insert_kids_session_logs_batch') &&
          !message.contains('could not find the function')) {
        rethrow;
      }
    }

    for (final log in logs) {
      await client.rpc(
        'insert_kids_session_log',
        params: {
          'p_local_id': log.id,
          'p_surah_id': log.surahId,
          'p_ayah_number': log.ayahNumber,
          'p_repeats_completed': log.repeatsCompleted,
          'p_points_earned': log.pointsEarned,
          'p_completed_at': log.completedAt.toUtc().toIso8601String(),
        },
      );
    }
  }

  Future<void> _pushReviewRecordsBatch(
    SupabaseClient client,
    List<AyahReviewRecord> records,
  ) async {
    if (records.isEmpty) return;
    const chunkSize = 500;
    for (var i = 0; i < records.length; i += chunkSize) {
      final end = min(i + chunkSize, records.length);
      final payload = records
          .sublist(i, end)
          .map(
            (r) => {
              'surah_id': r.surahId,
              'ayah_number': r.ayahNumber,
              'strength_level': r.strengthLevel,
              'interval_days': r.intervalDays,
              'last_reviewed_at': r.lastReviewedAt.toUtc().toIso8601String(),
              'next_review_date': r.nextReviewDate.toUtc().toIso8601String(),
              'total_reviews': r.totalReviews,
              'last_rating': r.lastRating?.name,
              'ease_factor': r.easeFactor,
              'lapses': r.lapses,
              'review_state': r.reviewState.name,
              'created_by_mode': r.createdByMode.name,
            },
          )
          .toList();
      await client.rpc(
        'upsert_ayah_review_records',
        params: {'p_data': payload},
      );
    }
  }

  Future<void> _upsertDailyPlanRow(
    SupabaseClient client,
    String userId,
    DailyPlan plan,
  ) async {
    await client.from('daily_plans_cloud').upsert({
      'user_id': userId,
      'surah_id': plan.surahId,
      'generated_at': plan.generatedAt.toUtc().toIso8601String(),
      'total_items': plan.totalItems,
      'completed_count': plan.requiredCompletedCount,
      'payload': DailyPlanModel.fromEntity(plan).toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  AyahReviewRecord _reviewRecordFromCloud(Map<String, dynamic> row) {
    return RemoteChildProductionSummaryBuilder.reviewRecordFromCloud(row);
  }

  /// Reconstructs the parent-facing production summary from cloud rows.
  ///
  /// Reuses existing pure logic only: [AyahReviewRecord.reviewClassification]
  /// (SRS due/near/far/memorized classification) and [SmartCoachEngine] (next
  /// recommendation) — no second engine is introduced for the parent side.
  RemoteChildProductionSummary _buildProductionSummary({
    required List<Map<String, dynamic>> reviewRows,
    required Map<String, dynamic>? dailyPlanRow,
    required List<Map<String, dynamic>> certRows,
    required Map<String, dynamic>? streakRow,
    required List<Map<String, dynamic>> activityRows,
  }) {
    return RemoteChildProductionSummaryBuilder(metrics: _metrics).build(
      reviewRows: reviewRows,
      dailyPlanRow: dailyPlanRow,
      certRows: certRows,
      streakRow: streakRow,
      activityRows: activityRows,
    );
  }
}
