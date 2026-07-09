import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../streak/data/models/streak_isar.dart';
import '../../../streak/data/models/daily_activity_isar.dart';
import '../../../xp/data/models/xp_isar.dart';
import '../../domain/entities/auth_error_code.dart';

class AuthFailure extends Failure {
  final AuthErrorCode code;
  AuthFailure(this.code) : super(code.name);
}

class AuthConfigurationFailure extends Failure {
  const AuthConfigurationFailure([
    super.message =
        'تسجيل الدخول السحابي غير مهيأ في هذا الإصدار. شغّل التطبيق بإعدادات SUPABASE_URL و SUPABASE_ANON_KEY أو استخدمه كضيف.',
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._isar, this._prefs);

  final Isar _isar;
  final SharedPreferences _prefs;
  static const Set<String> _authScopedPreferenceKeys = {
    // Copied from the authenticated Supabase display name on login. Keep
    // local-first Quran, Hifz, Memorization Plus, bookmarks, theme, and locale
    // intact so signing out does not destroy guest/offline progress.
    'user_profile',
  };

  bool get _isSupabaseInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  // Lazy getter — defers access until first use so the app doesn't crash
  // when Supabase was not initialized (offline / missing .env).
  SupabaseClient get _supabase => Supabase.instance.client;

  Either<Failure, SupabaseClient> _clientOrFailure() {
    if (!_isSupabaseInitialized) {
      return const Left(AuthConfigurationFailure());
    }
    return Right(_supabase);
  }

  @override
  AppUser? get currentUser {
    if (!_isSupabaseInitialized) return null;
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
  Stream<AppUser?> get authStateChanges {
    if (!_isSupabaseInitialized) return const Stream.empty();
    return _supabase.auth.onAuthStateChange
        .where((event) => event.event != AuthChangeEvent.passwordRecovery)
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
  }

  @override
  Stream<void> get passwordRecoveryChanges {
    if (!_isSupabaseInitialized) return const Stream.empty();
    return _supabase.auth.onAuthStateChange
        .where((event) => event.event == AuthChangeEvent.passwordRecovery)
        .map<void>((_) {});
  }

  // ─── Sign Up ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AppUser>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final clientResult = _clientOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user == null) {
        return Left(AuthFailure(AuthErrorCode.unknown));
      }

      // Supabase returns a user with an identities list.
      // If identities is empty it means the email is already registered.
      if (response.user!.identities != null &&
          response.user!.identities!.isEmpty) {
        return Left(
          AuthFailure(AuthErrorCode.emailAlreadyRegistered),
        );
      }

      // If email confirmation is required, the session will be null.
      // Inform the user they need to confirm their email.
      if (response.session == null) {
        return Left(
          AuthFailure(AuthErrorCode.emailNotConfirmed),
        );
      }

      final user = AppUser(
        id: response.user!.id,
        email: response.user!.email ?? '',
        displayName: displayName,
      );

      return Right(user);
    } on AuthException catch (e) {
      TaliaLogger.w('Auth sign-up error', e);
      return Left(AuthFailure(_mapAuthError(e.message)));
    } catch (e) {
      TaliaLogger.w('Unexpected sign-up error', e);
      return Left(AuthFailure(AuthErrorCode.unknown));
    }
  }

  // ─── Sign In ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final clientResult = _clientOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return Left(AuthFailure(AuthErrorCode.invalidCredentials));
      }

      final user = AppUser(
        id: response.user!.id,
        email: response.user!.email ?? '',
        displayName:
            response.user!.userMetadata?['display_name'] as String? ?? 'مستخدم',
      );

      return Right(user);
    } on AuthException catch (e) {
      TaliaLogger.w('Auth sign-in error', e);
      return Left(AuthFailure(_mapAuthError(e.message)));
    } catch (e) {
      TaliaLogger.w('Unexpected sign-in error', e);
      return Left(AuthFailure(AuthErrorCode.unknown));
    }
  }

  // ─── Resend Confirmation ─────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> resendConfirmation(String email) async {
    try {
      final clientResult = _clientOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      await client.auth.resend(type: OtpType.signup, email: email);
      return const Right(unit);
    } on AuthException catch (e) {
      TaliaLogger.w('Resend confirmation error', e);
      return Left(AuthFailure(_mapAuthError(e.message)));
    } catch (e) {
      TaliaLogger.w('Unexpected resend confirmation error', e);
      return Left(AuthFailure(AuthErrorCode.unknown));
    }
  }

  // ─── Reset Password ───────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> resetPassword(String email) async {
    try {
      final clientResult = _clientOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.passwordRecoveryRedirectTo,
      );
      return const Right(unit);
    } on AuthException catch (e) {
      TaliaLogger.w('Password reset error', e);
      return Left(AuthFailure(_mapAuthError(e.message)));
    } catch (e) {
      TaliaLogger.w('Unexpected password reset error', e);
      return Left(AuthFailure(AuthErrorCode.unknown));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePassword(String newPassword) async {
    try {
      final clientResult = _clientOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      await client.auth.updateUser(UserAttributes(password: newPassword));

      // Sign out immediately after a successful password update so the
      // recovery session is fully cleared. This prevents the app from
      // staying authenticated under an old recovery token, which would
      // cause login failures when the user tries to sign in with the new
      // password.
      try {
        await client.auth.signOut();
        await _clearLocalUserData();
      } catch (signOutError) {
        TaliaLogger.w(
          'Post-password-update sign-out failed (non-fatal)',
          signOutError,
        );
      }

      return const Right(unit);
    } on AuthException catch (e) {
      TaliaLogger.w('Password update error', e);
      return Left(AuthFailure(_mapAuthError(e.message)));
    } catch (e) {
      TaliaLogger.w('Unexpected password update error', e);
      return Left(AuthFailure(AuthErrorCode.unknown));
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      if (!_isSupabaseInitialized) return const Right(unit);
      await _supabase.auth.signOut();
      await _clearLocalUserData();
      return const Right(unit);
    } catch (e) {
      TaliaLogger.w('Sign-out error', e);
      return Left(AuthFailure(AuthErrorCode.unknown));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount() async {
    try {
      final clientResult = _clientOrFailure();
      final clientFailure = clientResult.fold(
        (failure) => failure,
        (_) => null,
      );
      if (clientFailure != null) return Left(clientFailure);
      final client = clientResult.getOrElse(
        () => throw StateError('unreachable'),
      );

      if (client.auth.currentUser == null) {
        return Left(AuthFailure(AuthErrorCode.userNotFound));
      }

      await client.rpc('delete_current_user');
      try {
        await client.auth.signOut();
      } catch (e) {
        TaliaLogger.w('Post-delete sign-out cleanup failed', e);
      }
      await _clearLocalUserData();
      return const Right(unit);
    } on PostgrestException catch (e) {
      TaliaLogger.w('Account deletion RPC error', e);
      final message = e.message.toLowerCase();
      if (message.contains('could not find the function') ||
          message.contains('delete_current_user') ||
          message.contains('schema cache')) {
        return const Left(
          ServerFailure(
            'تعذر حذف الحساب حالياً. يرجى المحاولة مرة أخرى لاحقاً.',
          ),
        );
      }
      return const Left(ServerFailure('تعذر حذف الحساب. حاول لاحقاً.'));
    } on AuthException catch (e) {
      TaliaLogger.w('Account deletion auth error', e);
      return Left(AuthFailure(_mapAuthError(e.message)));
    } catch (e) {
      TaliaLogger.w('Unexpected account deletion error', e);
      return const Left(ServerFailure('تعذر حذف الحساب. حاول لاحقاً.'));
    }
  }

  // ─── Cloud Sync ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> syncProgressToCloud() async {
    try {
      if (!_isSupabaseInitialized) return const Right(unit);
      final user = _supabase.auth.currentUser;
      if (user == null) return const Right(unit);

      await _syncStreakToCloud();
      await _syncXpToCloud();
      await _syncDailyActivitiesToCloud();

      TaliaLogger.i('Sync to cloud completed');
      return const Right(unit);
    } catch (e) {
      TaliaLogger.w('Sync to cloud failed', e);
      return const Left(ServerFailure('فشل المزامنة مع السحابة'));
    }
  }

  @override
  Future<Either<Failure, Unit>> pullProgressFromCloud() async {
    try {
      if (!_isSupabaseInitialized) return const Right(unit);
      final user = _supabase.auth.currentUser;
      if (user == null) return const Right(unit);

      await _pullStreakFromCloud(user.id);
      await _pullXpFromCloud(user.id);
      await _pullDailyActivitiesFromCloud(user.id);

      TaliaLogger.i('Pull from cloud completed');
      return const Right(unit);
    } catch (e) {
      TaliaLogger.w('Pull from cloud failed', e);
      return const Left(ServerFailure('فشل استرجاع البيانات من السحابة'));
    }
  }

  // ─── Streak Sync ────────────────────────────────────────────────────────────

  Future<void> _syncStreakToCloud() async {
    final streak = await _isar.streakIsars.get(1);
    if (streak == null) return;

    await _supabase.rpc(
      'upsert_streak',
      params: {
        'p_current_streak': streak.currentStreak,
        'p_longest_streak': streak.longestStreak,
        'p_last_activity_date': _toDateOnlyString(streak.lastActivityDate),
        'p_freezes_available': streak.freezesAvailable,
      },
    );
  }

  Future<void> _pullStreakFromCloud(String userId) async {
    final rows = await _supabase.from('streaks').select().eq('user_id', userId);

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

    await _supabase.rpc('upsert_xp', params: {'p_total_xp': xp.totalXp});
  }

  Future<void> _pullXpFromCloud(String userId) async {
    final rows = await _supabase.from('xp').select().eq('user_id', userId);

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

  // ─── Daily Activities Sync ──────────────────────────────────────────────────

  Future<void> _syncDailyActivitiesToCloud() async {
    final activities = await _isar.dailyActivityIsars.where().findAll();
    if (activities.isEmpty) return;

    // C04 FIX: Batch all daily activities into a single RPC call
    final data = activities
        .map((a) => {'day_key': a.dayKey, 'activity_count': a.activityCount})
        .toList();

    await _supabase.rpc(
      'upsert_daily_activities_batch',
      params: {'p_data': jsonEncode(data)},
    );
  }

  Future<void> _pullDailyActivitiesFromCloud(String userId) async {
    final rows = await _supabase
        .from('daily_activities')
        .select()
        .eq('user_id', userId);

    if (rows.isEmpty) return;

    await _isar.writeTxn(() async {
      for (final row in rows) {
        final dayKey = row['day_key'] as int;
        final cloudCount = row['activity_count'] as int;

        final local = await _isar.dailyActivityIsars
            .where()
            .dayKeyEqualTo(dayKey)
            .findFirst();

        if (local != null) {
          if (cloudCount > local.activityCount) {
            local.activityCount = cloudCount;
            await _isar.dailyActivityIsars.put(local);
          }
        } else {
          final newRecord = DailyActivityIsar()
            ..dayKey = dayKey
            ..activityCount = cloudCount;
          await _isar.dailyActivityIsars.put(newRecord);
        }
      }
    });
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _clearLocalUserData() async {
    for (final key in _authScopedPreferenceKeys) {
      await _prefs.remove(key);
    }
  }

  String? _toDateOnlyString(DateTime? value) =>
      value?.toIso8601String().substring(0, 10);

  /// Maps Supabase auth error messages to strongly-typed error codes
  AuthErrorCode _mapAuthError(String message) {
    final lower = message.toLowerCase();

    // Email already registered
    if (lower.contains('already registered') ||
        (lower.contains('email') && lower.contains('already'))) {
      return AuthErrorCode.emailAlreadyRegistered;
    }

    // Email not confirmed — most common cause of "invalid credentials" confusion
    if (lower.contains('email not confirmed') ||
        lower.contains('email_not_confirmed') ||
        lower.contains('not confirmed')) {
      return AuthErrorCode.emailNotConfirmed;
    }

    // Wrong password or email
    if (lower.contains('invalid login credentials') ||
        (lower.contains('invalid') && lower.contains('credentials'))) {
      return AuthErrorCode.invalidCredentials;
    }

    // Password too short
    if (lower.contains('password') && lower.contains('short')) {
      return AuthErrorCode.passwordTooShort;
    }

    // Invalid email format
    if (lower.contains('email') && lower.contains('invalid')) {
      return AuthErrorCode.invalidEmailFormat;
    }

    // Too many requests
    if (lower.contains('too many') || lower.contains('rate limit')) {
      return AuthErrorCode.tooManyRequests;
    }

    // Network error
    if (lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('socket')) {
      return AuthErrorCode.networkError;
    }

    // Same password as the current one
    if (lower.contains('same password') ||
        lower.contains('should be different') ||
        lower.contains('different from') ||
        lower.contains('password_same_as_old') ||
        lower.contains('new password should be different')) {
      return AuthErrorCode.samePasswordAsOld;
    }

    // Missing/expired password recovery session
    if (lower.contains('session missing') ||
        lower.contains('session_missing') ||
        lower.contains('no current session') ||
        lower.contains('missing session')) {
      return AuthErrorCode.sessionExpired;
    }

    // User not found
    if (lower.contains('user not found') || lower.contains('no user')) {
      return AuthErrorCode.userNotFound;
    }

    TaliaLogger.w('Unmapped Supabase auth error');
    return AuthErrorCode.unknown;
  }
}
