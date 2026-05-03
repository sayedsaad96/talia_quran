import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/app_failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../hifz/data/models/isar_ayah_progress.dart';
import '../../../hifz/domain/entities/hifz_entities.dart';
import '../../../streak/data/models/streak_isar.dart';
import '../../../xp/data/models/xp_isar.dart';

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Auth error']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._isar);

  final SupabaseClient _supabase = Supabase.instance.client;
  final Isar _isar;

  @override
  AppUser? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['display_name'] as String? ?? 'مستخدم',
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }

  @override
  Stream<AppUser?> get authStateChanges => _supabase.auth.onAuthStateChange
      .map((event) => event.session?.user)
      .map(
        (user) => user == null
            ? null
            : AppUser(
                id: user.id,
                email: user.email ?? '',
                displayName:
                    user.userMetadata?['display_name'] as String? ?? 'مستخدم',
                avatarUrl: user.userMetadata?['avatar_url'] as String?,
              ),
      );

  // ─── Sign Up ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AppUser>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user == null) {
        return const Left(AuthFailure('فشل إنشاء الحساب'));
      }

      final user = AppUser(
        id: response.user!.id,
        email: response.user!.email ?? '',
        displayName: displayName,
      );

      // Sync local progress to cloud (non-blocking)
      try {
        await syncProgressToCloud();
      } catch (e) {
        debugPrint('⚠️ Post-signup sync failed (non-critical): $e');
      }

      return Right(user);
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      return Left(AuthFailure(_mapAuthError(e.message)));
    } catch (e) {
      debugPrint('Sign-up error: $e');
      return const Left(AuthFailure('حدث خطأ أثناء إنشاء الحساب'));
    }
  }

  // ─── Sign In ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const Left(AuthFailure('فشل تسجيل الدخول'));
      }

      final user = AppUser(
        id: response.user!.id,
        email: response.user!.email ?? '',
        displayName:
            response.user!.userMetadata?['display_name'] as String? ?? 'مستخدم',
      );

      // Sync local progress to cloud (non-blocking)
      try {
        await syncProgressToCloud();
      } catch (e) {
        debugPrint('⚠️ Post-sign-in sync failed (non-critical): $e');
      }

      return Right(user);
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      return Left(AuthFailure(_mapAuthError(e.message)));
    } catch (e) {
      debugPrint('Sign-in error: $e');
      return const Left(AuthFailure('حدث خطأ أثناء تسجيل الدخول'));
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _supabase.auth.signOut();
      return const Right(unit);
    } catch (e) {
      debugPrint('Sign-out error: $e');
      return const Left(AuthFailure('حدث خطأ أثناء تسجيل الخروج'));
    }
  }

  // ─── Cloud Sync ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> syncProgressToCloud() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return const Right(unit);

      await _syncAyahProgressToCloud(user.id);
      await _syncStreakToCloud();
      await _syncXpToCloud();

      debugPrint('✅ Sync to cloud completed');
      return const Right(unit);
    } catch (e) {
      debugPrint('❌ Sync to cloud failed: $e');
      return const Left(ServerFailure('فشل المزامنة مع السحابة'));
    }
  }

  @override
  Future<Either<Failure, Unit>> pullProgressFromCloud() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return const Right(unit);

      await _pullAyahProgressFromCloud(user.id);
      await _pullStreakFromCloud(user.id);
      await _pullXpFromCloud(user.id);

      debugPrint('✅ Pull from cloud completed');
      return const Right(unit);
    } catch (e) {
      debugPrint('❌ Pull from cloud failed: $e');
      return const Left(ServerFailure('فشل استرجاع البيانات من السحابة'));
    }
  }

  // ─── Ayah Progress Sync ─────────────────────────────────────────────────────

  Future<void> _syncAyahProgressToCloud(String userId) async {
    final allProgress =
        await _isar.isarAyahProgress.where().findAll();

    if (allProgress.isEmpty) return;

    final data = allProgress.map((p) => {
          'surah_id': p.surahId,
          'ayah_number': p.ayahNumber,
          'status': p.status.name,
          'repetitions': p.repetitions,
          'next_review_date': p.nextReviewDate.toUtc().toIso8601String(),
          'last_review_date': p.lastReviewDate.toUtc().toIso8601String(),
        }).toList();

    await _supabase.rpc('upsert_ayah_progress', params: {
      'p_data': jsonEncode(data),
    });
  }

  Future<void> _pullAyahProgressFromCloud(String userId) async {
    final rows = await _supabase
        .from('ayah_progress')
        .select()
        .eq('user_id', userId);

    if (rows.isEmpty) return;

    await _isar.writeTxn(() async {
      for (final row in rows) {
        final existing = await _isar.isarAyahProgress
            .where()
            .compositeKeyEqualTo('${row['surah_id']}_${row['ayah_number']}')
            .findFirst();

        final cloudDate = DateTime.parse(row['last_review_date'] as String);
        final localDate = existing?.lastReviewDate;

        if (existing == null || localDate == null || cloudDate.isAfter(localDate)) {
          final isar = IsarAyahProgress()
            ..compositeKey = '${row['surah_id']}_${row['ayah_number']}'
            ..surahId = row['surah_id'] as int
            ..ayahNumber = row['ayah_number'] as int
            ..status = _parseAyahStatus(row['status'] as String)
            ..repetitions = row['repetitions'] as int
            ..nextReviewDate = DateTime.parse(row['next_review_date'] as String)
            ..lastReviewDate = cloudDate;

          if (existing != null) isar.id = existing.id;
          await _isar.isarAyahProgress.put(isar);
        }
      }
    });
  }

  // ─── Streak Sync ────────────────────────────────────────────────────────────

  Future<void> _syncStreakToCloud() async {
    final streak = await _isar.streakIsars.get(1);
    if (streak == null) return;

    await _supabase.rpc('upsert_streak', params: {
      'p_current_streak': streak.currentStreak,
      'p_longest_streak': streak.longestStreak,
      'p_last_activity_date': streak.lastActivityDate?.toIso8601String().split('T').first,
      'p_freezes_available': streak.freezesAvailable,
    });
  }

  Future<void> _pullStreakFromCloud(String userId) async {
    final rows = await _supabase
        .from('streaks')
        .select()
        .eq('user_id', userId);

    if (rows.isEmpty) return;
    final cloud = rows.first;

    await _isar.writeTxn(() async {
      final local = await _isar.streakIsars.get(1) ?? StreakIsar();

      local.currentStreak =
          local.currentStreak > (cloud['current_streak'] as int)
              ? local.currentStreak
              : cloud['current_streak'] as int;
      local.longestStreak =
          local.longestStreak > (cloud['longest_streak'] as int)
              ? local.longestStreak
              : cloud['longest_streak'] as int;
      local.freezesAvailable = cloud['freezes_available'] as int;

      if (cloud['last_activity_date'] != null) {
        final cloudDate = DateTime.parse(cloud['last_activity_date'] as String);
        if (local.lastActivityDate == null ||
            cloudDate.isAfter(local.lastActivityDate!)) {
          local.lastActivityDate = cloudDate;
        }
      }

      await _isar.streakIsars.put(local);
    });
  }

  // ─── XP Sync ────────────────────────────────────────────────────────────────

  Future<void> _syncXpToCloud() async {
    final xp = await _isar.xpIsars.get(1);
    if (xp == null) return;

    await _supabase.rpc('upsert_xp', params: {
      'p_total_xp': xp.totalXp,
    });
  }

  Future<void> _pullXpFromCloud(String userId) async {
    final rows = await _supabase
        .from('xp')
        .select()
        .eq('user_id', userId);

    if (rows.isEmpty) return;
    final cloud = rows.first;

    await _isar.writeTxn(() async {
      final local = await _isar.xpIsars.get(1) ?? XpIsar();
      final cloudXp = cloud['total_xp'] as int;
      if (cloudXp > local.totalXp) {
        local.totalXp = cloudXp;
      }
      await _isar.xpIsars.put(local);
    });
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  AyahStatus _parseAyahStatus(String status) {
    switch (status) {
      case 'learning':
        return AyahStatus.learning;
      case 'review':
        return AyahStatus.review;
      case 'memorized':
        return AyahStatus.memorized;
      default:
        return AyahStatus.notStarted;
    }
  }

  /// Maps Supabase auth error messages to Arabic user-friendly messages
  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('email') && lower.contains('already')) {
      return 'البريد الإلكتروني مسجل بالفعل';
    }
    if (lower.contains('invalid') && lower.contains('credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (lower.contains('password') && lower.contains('short')) {
      return 'كلمة المرور قصيرة جداً (6 أحرف على الأقل)';
    }
    if (lower.contains('email') && lower.contains('invalid')) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'لا يوجد اتصال بالإنترنت';
    }
    return 'حدث خطأ، حاول مرة أخرى';
  }
}
