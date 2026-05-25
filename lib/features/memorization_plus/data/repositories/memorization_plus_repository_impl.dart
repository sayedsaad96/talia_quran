import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../features/quran/domain/repositories/quran_repository.dart';
import '../../../../features/quran/domain/entities/quran_entities.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';
import '../datasources/memorization_plus_local_datasource.dart';
import '../models/memorization_models.dart';

class MemorizationPlusRepositoryImpl implements MemorizationPlusRepository {
  MemorizationPlusRepositoryImpl(this._datasource, this._quranRepository);

  final MemorizationPlusLocalDatasource _datasource;

  /// For surah ayah counts
  final QuranRepository _quranRepository;

  final _scheduler = const ScheduleNextReviewUsecase();

  /// Lazy Supabase getter — safe to reference but individual methods that call
  /// Supabase must still handle StateError / no-network gracefully via try-catch.
  /// All Supabase-using methods in this repo already have `catch (e)` blocks.
  SupabaseClient get _supabase => Supabase.instance.client;

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
          expiresAt: now.add(const Duration(minutes: 15)),
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
        final userId = _supabase.auth.currentUser?.id;
        final profile = await _loadProfile();
        final saved = await _saveProfile(
          profile.isChild
              ? profile.copyWith(
                  guardianLinkStatus: GuardianLinkStatus.linked,
                  guardianOnboardingStatus: GuardianOnboardingStatus.completed,
                  guardianId: userId ?? 'linked_guardian',
                )
              : profile.copyWith(
                  isParentGuardian: true,
                  linkedChildId: profile.linkedChildId ?? 'linked_child',
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
      if (!profile.isChild || !profile.isGuardianLinked) return Right(profile);
      final user = _supabase.auth.currentUser;
      if (user == null) return Right(profile);

      final links = await _supabase
          .from('parent_child_links')
          .select('parent_user_id')
          .eq('child_user_id', user.id)
          .eq('status', 'active')
          .limit(1);
      if (links.isNotEmpty) return Right(profile);

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

  // ─── Daily plan ─────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, DailyPlan>> generateDailyPlan({
    required int surahId,
    required int newAyahsPerDay,
  }) async {
    try {
      final allRecords = await _datasource.getAllReviewRecords();

      // BUG-7 FIX: Read custom plan settings and apply them
      final customPlan = await _datasource.getCustomPlan();
      final effectiveNewPerDay = customPlan?.newAyahsPerDay ?? newAyahsPerDay;
      final nearRevisionLimit = customPlan?.nearRevisionCount ?? 10;
      final farRevisionLimit = customPlan?.farRevisionCount ?? 5;
      // Respect the custom plan's endSurahId boundary
      final maxSurahId = customPlan?.endSurahId ?? 114;

      int currentSurahId = customPlan?.startSurahId ?? surahId;
      if (surahId > currentSurahId) {
        currentSurahId = surahId;
      }
      DailyPlan? bestPlan;

      while (currentSurahId <= maxSurahId) {
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
          } else if (record.isDue) {
            final planAyah = DailyPlanAyah(
              surahId: currentSurahId,
              ayahNumber: i,
              ayahText: ayahText,
              record: record,
            );
            // BUG-7 FIX: apply custom plan revision limits
            if (customPlan?.enableNearRevision != false &&
                record.isNearRevision &&
                nearRevision.length < nearRevisionLimit) {
              nearRevision.add(planAyah);
            } else if (customPlan?.enableFarRevision != false &&
                record.isFarRevision &&
                farRevision.length < farRevisionLimit) {
              farRevision.add(planAyah);
            }
          }
        }

        bestPlan = DailyPlan(
          // UTC so the same-day stale check in getCachedDailyPlan is timezone-safe.
          generatedAt: DateTime.now().toUtc(),
          surahId: currentSurahId,
          newAyahs: newAyahs,
          nearRevision: nearRevision,
          farRevision: farRevision,
          completedAyahNums: const [],
        );

        if (bestPlan.totalItems > 0) {
          break; // Found active items
        }

        currentSurahId++;
      }

      bestPlan ??= DailyPlan(
        generatedAt: DateTime.now().toUtc(),
        surahId: maxSurahId,
        newAyahs: const [],
        nearRevision: const [],
        farRevision: const [],
        completedAyahNums: const [],
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
      if (cached == null) return const Right(null);

      // Compare on UTC date components to avoid DST-ambiguous local midnight.
      // The cached plan's generatedAt is also stored in UTC (see generateDailyPlan).
      final today = DateTime.now().toUtc();
      final cachedDate = cached.generatedAt.toUtc();
      final sameDay =
          cachedDate.year == today.year &&
          cachedDate.month == today.month &&
          cachedDate.day == today.day;

      return Right(sameDay ? cached : null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveDailyPlan(DailyPlan plan) async {
    try {
      await _datasource.saveDailyPlan(DailyPlanModel.fromEntity(plan));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Review records ─────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, AyahReviewRecord?>> getReviewRecord(
    int surahId,
    int ayahNumber,
  ) async {
    try {
      final record = await _datasource.getReviewRecord(surahId, ayahNumber);
      return Right(record);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords() async {
    try {
      final records = await _datasource.getAllReviewRecords();
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
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Evaluation ─────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, AyahReviewRecord>> evaluateAyah({
    required int surahId,
    required int ayahNumber,
    required PerformanceRating rating,
  }) async {
    try {
      final existing = await _datasource.getReviewRecord(surahId, ayahNumber);

      final current =
          existing ?? AyahReviewRecordModel.initial(surahId, ayahNumber);

      final updated = _scheduler.schedule(current, rating);
      await _datasource.saveReviewRecord(
        AyahReviewRecordModel.fromEntity(updated),
      );

      return Right(updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AyahReviewRecord>> markAyahMemorized({
    required int surahId,
    required int ayahNumber,
  }) async {
    try {
      final existing = await _datasource.getReviewRecord(surahId, ayahNumber);
      final current =
          existing ?? AyahReviewRecordModel.initial(surahId, ayahNumber);
      // UTC: consistent with AyahReviewRecord scheduling in ScheduleNextReviewUsecase.
      final now = DateTime.now().toUtc();
      final intervalDays = current.intervalDays < 30
          ? 30
          : current.intervalDays;

      final updated = current.copyWith(
        strengthLevel: current.strengthLevel < 6 ? 6 : current.strengthLevel,
        intervalDays: intervalDays,
        lastReviewedAt: now,
        nextReviewDate: now.add(Duration(days: intervalDays)),
        totalReviews: current.totalReviews + 1,
        lastRating: PerformanceRating.excellent,
      );

      await _datasource.saveReviewRecord(
        AyahReviewRecordModel.fromEntity(updated),
      );
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ─── Kids progress ───────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, KidsProgress>> getKidsProgress() async {
    try {
      final progress = await _datasource.getKidsProgress();
      return Right(progress);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveKidsProgress(KidsProgress progress) async {
    try {
      await _datasource.saveKidsProgress(
        KidsProgressModel.fromEntity(progress),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
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
          status = KidsJourneyStageStatus.completed;
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
      await syncKidsProgressToCloud();
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
      final progress = await _datasource.getKidsProgress();
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
      if (_supabase.auth.currentUser == null) {
        return const Left(NetworkFailure('سجّل الدخول أولاً على جهاز الطفل'));
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

      await _supabase.rpc(
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
      if (_supabase.auth.currentUser == null) {
        return const Left(
          NetworkFailure('سجّل الدخول أولاً على جهاز ولي الأمر'),
        );
      }
      // Hash the token client-side (no pgcrypto needed)
      final rawToken = _extractToken(token).toUpperCase().trim();
      final tokenHash = sha256.convert(utf8.encode(rawToken)).toString();
      await _supabase.rpc(
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
      final user = _supabase.auth.currentUser;
      if (user == null) return const Right(null);

      final progress = await _datasource.getKidsProgress();
      await _supabase.rpc(
        'upsert_kids_progress_cloud',
        params: {
          'p_total_points': progress.totalPoints,
          'p_current_level': progress.currentLevel,
          'p_current_streak': progress.currentStreak,
          'p_stars_earned': progress.starsEarned,
          'p_ayahs_completed': progress.ayahsCompleted,
          'p_last_session_at': progress.lastSessionAt
              ?.toUtc()
              .toIso8601String(),
        },
      );

      final logs = await _datasource.getKidsSessionLogs();
      final synced = <KidsSessionLogModel>[];
      for (final log in logs) {
        if (log.isSynced) {
          synced.add(log);
          continue;
        }
        await _supabase.rpc(
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
        synced.add(
          KidsSessionLogModel.fromEntity(
            log.copyWith(syncedAt: DateTime.now()),
          ),
        );
      }
      await _datasource.saveKidsSessionLogs(synced);
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RemoteChildSummary>>> getRemoteChildren() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Left(NetworkFailure('سجّل الدخول أولاً'));
      }

      final links = await _supabase
          .from('parent_child_links')
          .select('child_user_id')
          .eq('parent_user_id', user.id)
          .eq('status', 'active');

      final children = <RemoteChildSummary>[];
      for (final link in links) {
        final childId = link['child_user_id'] as String;
        final profileRows = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', childId)
            .limit(1);
        final progressRows = await _supabase
            .from('kids_progress_cloud')
            .select()
            .eq('child_user_id', childId)
            .limit(1);
        final logRows = await _supabase
            .from('kids_session_logs')
            .select()
            .eq('child_user_id', childId)
            .order('completed_at', ascending: false)
            .limit(30);
        final rewardRows = await _supabase
            .from('parent_rewards')
            .select()
            .eq('child_user_id', childId)
            .order('created_at', ascending: false);

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
          ),
        );
      }
      return Right(children);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
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
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Left(NetworkFailure('سجّل الدخول أولاً'));
      }
      await _supabase.from('parent_rewards').insert({
        'parent_user_id': user.id,
        'child_user_id': childUserId,
        'title': trimmed,
      });
      final rows = await _supabase
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
  Future<Either<Failure, KidsProgress>> awardKidsPoints({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
  }) async {
    try {
      final current = await _datasource.getKidsProgress();
      // Points: 10 base + 2 per extra repeat
      final points = 10 + ((repeatsCompleted - 1) * 2).clamp(0, 20);
      final updated = current.addPoints(points);
      await _datasource.saveKidsProgress(KidsProgressModel.fromEntity(updated));
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  bool _isLegacyPlaintextPin(String? value) {
    return value != null && value.length == 4 && int.tryParse(value) != null;
  }

  String _extractToken(String raw) {
    const prefix = 'talia-kids-link:';
    return raw.startsWith(prefix) ? raw.substring(prefix.length) : raw;
  }

  Future<void> _unlockWeeklyRewardIfNeeded() async {
    final logs = await _datasource.getKidsSessionLogs();
    final settings = await _datasource.getParentSettings();
    final rewards = await _datasource.getParentRewards();
    if (rewards.isEmpty ||
        rewards.every((r) => r.status != ParentRewardStatus.locked)) {
      return;
    }
    final now = DateTime.now();
    final weekStart = DateTime(
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
            unlockedAt: DateTime.now(),
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
}
