import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/auth/auth_session_recovery_policy.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/identity/account_data_reset.dart';
import '../../../../core/sync/sync_acknowledgement.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../streak/data/models/streak_isar.dart';
import '../../../streak/data/models/daily_activity_isar.dart';
import '../../../xp/data/models/xp_isar.dart';
import '../../domain/entities/auth_error_code.dart';
import '../../domain/entities/auth_session_recovery.dart';
import '../../../progress/data/datasources/progress_local_datasource.dart';

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
  AuthRepositoryImpl(this._isar, this._accountDataReset, [this._prefs]);

  final Isar _isar;
  final AccountDataReset _accountDataReset;
  final SharedPreferences? _prefs;

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

  @override
  Future<AuthSessionRecovery> recoverSessionAfterAuthError(Object error) async {
    if (!_isSupabaseInitialized) {
      return AuthSessionRecovery.transientFailure;
    }

    Object? refreshError;
    try {
      final response = await _supabase.auth.refreshSession();
      if (response.session != null && response.user != null) {
        return AuthSessionRecovery.recovered;
      }
    } catch (caught) {
      refreshError = caught;
      TaliaLogger.w('Session refresh recovery failed', caught);
    }

    if (AuthSessionRecoveryPolicy.isTerminal(error) ||
        (refreshError != null &&
            AuthSessionRecoveryPolicy.isTerminal(refreshError))) {
      try {
        await _supabase.auth.signOut(scope: SignOutScope.local);
      } catch (signOutError) {
        TaliaLogger.e('Failed to clear terminal local session', signOutError);
      }
      return AuthSessionRecovery.terminalFailure;
    }
    return AuthSessionRecovery.transientFailure;
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
        return Left(AuthFailure(AuthErrorCode.emailAlreadyRegistered));
      }

      // If email confirmation is required, the session will be null.
      // Inform the user they need to confirm their email.
      if (response.session == null) {
        return Left(AuthFailure(AuthErrorCode.emailNotConfirmed));
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
        final departingOwnerId = client.auth.currentUser?.id;
        await client.auth.signOut();
        await _clearLocalUserData(departingOwnerId: departingOwnerId);
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
  Future<Either<Failure, Unit>> signOut({
    bool preserveAccountData = false,
  }) async {
    try {
      if (!_isSupabaseInitialized) {
        // A normal offline logout still clears account data. Forced logout
        // after a failed flush retains it under its existing owner scope.
        if (!preserveAccountData) {
          await _clearLocalUserData(preservePendingBookmarkRecovery: false);
        }
        return const Right(unit);
      }
      final departingOwnerId = _supabase.auth.currentUser?.id;
      await _supabase.auth.signOut();
      if (!preserveAccountData) {
        await _clearLocalUserData(
          departingOwnerId: departingOwnerId,
          preservePendingBookmarkRecovery: false,
        );
      }
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

      final departingOwnerId = client.auth.currentUser?.id;
      await client.rpc('delete_current_user');
      // `auth.users` deletion revokes refresh credentials server-side, but an
      // already issued access token remains valid until expiry. Clear the
      // device session locally and fail closed if that cannot be confirmed.
      await client.auth.signOut(scope: SignOutScope.local);
      if (client.auth.currentSession != null ||
          client.auth.currentUser != null) {
        return const Left(
          ServerFailure('تم حذف الحساب، لكن تعذر إنهاء الجلسة على هذا الجهاز.'),
        );
      }
      if (departingOwnerId != null) {
        return await finalizeDeletedAccountLocallyAfterRemoteDeletion(
          departingOwnerId,
        );
      }
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

  /// Runs only after remote deletion and local session invalidation are both
  /// confirmed. Failure to create the optional guest copy must not claim that
  /// the already-deleted remote account can be deleted again.
  Future<Either<Failure, Unit>>
  finalizeDeletedAccountLocallyAfterRemoteDeletion(String ownerId) async {
    try {
      await _accountDataReset.preserveDeletedAccountLocally(
        departingOwnerId: ownerId,
      );
    } catch (error, stackTrace) {
      TaliaLogger.w(
        'Remote account deletion succeeded, but local guest preservation was incomplete; owner-scoped recovery data was retained',
        error,
        stackTrace,
      );
    }
    return const Right(unit);
  }

  // ─── Cloud Sync ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> syncProgressToCloud() =>
      _syncProgressToCloud(allowAuthRecovery: true);

  Future<Either<Failure, Unit>> _syncProgressToCloud({
    required bool allowAuthRecovery,
  }) async {
    try {
      if (!_isSupabaseInitialized) return const Right(unit);
      final user = _supabase.auth.currentUser;
      if (user == null) return const Right(unit);

      await _syncStreakToCloud();
      await _syncXpToCloud();
      await _syncDailyActivitiesToCloud();
      await _pushReadingProgressToCloud();

      TaliaLogger.i('Sync to cloud completed');
      return const Right(unit);
    } catch (e) {
      TaliaLogger.w('Sync to cloud failed', e);
      if (allowAuthRecovery && _isAuthenticationFailure(e)) {
        final recovery = await recoverSessionAfterAuthError(e);
        if (recovery == AuthSessionRecovery.recovered) {
          return _syncProgressToCloud(allowAuthRecovery: false);
        }
        if (recovery == AuthSessionRecovery.terminalFailure) {
          return Left(AuthFailure(AuthErrorCode.sessionExpired));
        }
      }
      return const Left(ServerFailure('فشل المزامنة مع السحابة'));
    }
  }

  @override
  Future<Either<Failure, Unit>> pullProgressFromCloud() =>
      _pullProgressFromCloud(allowAuthRecovery: true);

  Future<Either<Failure, Unit>> _pullProgressFromCloud({
    required bool allowAuthRecovery,
  }) async {
    try {
      if (!_isSupabaseInitialized) return const Right(unit);
      final user = _supabase.auth.currentUser;
      if (user == null) return const Right(unit);

      await _pullStreakFromCloud(user.id);
      await _pullXpFromCloud(user.id);
      await _pullDailyActivitiesFromCloud(user.id);
      await _pullReadingProgressFromCloud(user.id);

      TaliaLogger.i('Pull from cloud completed');
      return const Right(unit);
    } catch (e) {
      TaliaLogger.w('Pull from cloud failed', e);
      if (allowAuthRecovery && _isAuthenticationFailure(e)) {
        final recovery = await recoverSessionAfterAuthError(e);
        if (recovery == AuthSessionRecovery.recovered) {
          return _pullProgressFromCloud(allowAuthRecovery: false);
        }
        if (recovery == AuthSessionRecovery.terminalFailure) {
          return Left(AuthFailure(AuthErrorCode.sessionExpired));
        }
      }
      return const Left(ServerFailure('فشل استرجاع البيانات من السحابة'));
    }
  }

  bool _isAuthenticationFailure(Object error) =>
      error is AuthException || AuthSessionRecoveryPolicy.isTerminal(error);

  @override
  Future<bool> hasPendingCloudPush() async {
    final streak = await _isar.streakIsars.get(1);
    if (streak != null && _needsCloudPush(streak.cloudDirty)) return true;

    final xp = await _isar.xpIsars.get(1);
    if (xp != null && _needsCloudPush(xp.cloudDirty)) return true;

    final dirtyActivities = await _isar.dailyActivityIsars
        .filter()
        .group((q) => q.cloudDirtyEqualTo(true).or().cloudDirtyIsNull())
        .findAll();
    if (dirtyActivities.isNotEmpty) return true;

    // Reading progress dirty flag.
    if (_prefs?.getBool(ProgressLocalDatasourceImpl.kReadPagesCloudDirty) ==
        true) {
      return true;
    }

    return false;
  }

  // ─── Streak Sync ────────────────────────────────────────────────────────────

  static bool _needsCloudPush(bool? cloudDirty) => cloudDirty != false;

  Future<void> _syncStreakToCloud() async {
    final streak = await _isar.streakIsars.get(1);
    if (streak == null || !_needsCloudPush(streak.cloudDirty)) return;

    final outbound = <String, Object?>{
      'current_streak': streak.currentStreak,
      'longest_streak': streak.longestStreak,
      'last_activity_date': _toDateOnlyString(streak.lastActivityDate),
      'freezes_available': streak.freezesAvailable,
    };

    await _supabase.rpc(
      'upsert_streak',
      params: {
        'p_current_streak': outbound['current_streak'],
        'p_longest_streak': outbound['longest_streak'],
        'p_last_activity_date': outbound['last_activity_date'],
        'p_freezes_available': outbound['freezes_available'],
      },
    );

    await _isar.writeTxn(() async {
      final latest = await _isar.streakIsars.get(1);
      if (latest == null) return;
      final current = <String, Object?>{
        'current_streak': latest.currentStreak,
        'longest_streak': latest.longestStreak,
        'last_activity_date': _toDateOnlyString(latest.lastActivityDate),
        'freezes_available': latest.freezesAvailable,
      };
      if (!SyncAcknowledgement.matches(outbound: outbound, current: current)) {
        return;
      }
      latest.cloudDirty = false;
      latest.lastSyncedAt = DateTime.now().toUtc();
      await _isar.streakIsars.put(latest);
    });
  }

  Future<void> _pullStreakFromCloud(String userId) async {
    final rows = await _supabase.from('streaks').select().eq('user_id', userId);

    if (rows.isEmpty) return;
    final cloud = rows.first;

    await _isar.writeTxn(() async {
      final local = await _isar.streakIsars.get(1) ?? StreakIsar();

      final cloudCurrent = cloud['current_streak'] as int;
      final cloudLongest = cloud['longest_streak'] as int;
      final localHigher =
          local.currentStreak > cloudCurrent ||
          local.longestStreak > cloudLongest;

      local.currentStreak = local.currentStreak > cloudCurrent
          ? local.currentStreak
          : cloudCurrent;
      local.longestStreak = local.longestStreak > cloudLongest
          ? local.longestStreak
          : cloudLongest;
      local.freezesAvailable = cloud['freezes_available'] as int;

      if (cloud['last_activity_date'] != null) {
        final cloudDate = DateTime.parse(cloud['last_activity_date'] as String);
        if (local.lastActivityDate == null ||
            cloudDate.isAfter(local.lastActivityDate!)) {
          local.lastActivityDate = cloudDate;
        }
      }

      // Keep cloudDirty = true if local state was higher, so subsequent push syncs it up!
      local.cloudDirty = localHigher;
      local.lastSyncedAt = DateTime.now().toUtc();
      await _isar.streakIsars.put(local);
    });
  }

  // ─── XP Sync ────────────────────────────────────────────────────────────────

  Future<void> _syncXpToCloud() async {
    final xp = await _isar.xpIsars.get(1);
    if (xp == null || !_needsCloudPush(xp.cloudDirty)) return;

    final outbound = <String, Object?>{'total_xp': xp.totalXp};

    await _supabase.rpc(
      'upsert_xp',
      params: {'p_total_xp': outbound['total_xp']},
    );

    await _isar.writeTxn(() async {
      final latest = await _isar.xpIsars.get(1);
      if (latest == null) return;
      if (!SyncAcknowledgement.matches(
        outbound: outbound,
        current: {'total_xp': latest.totalXp},
      )) {
        return;
      }
      latest.cloudDirty = false;
      latest.lastSyncedAt = DateTime.now().toUtc();
      await _isar.xpIsars.put(latest);
    });
  }

  Future<void> _pullXpFromCloud(String userId) async {
    final rows = await _supabase.from('xp').select().eq('user_id', userId);

    if (rows.isEmpty) return;
    final cloud = rows.first;

    await _isar.writeTxn(() async {
      final local = await _isar.xpIsars.get(1) ?? XpIsar();
      final cloudXp = cloud['total_xp'] as int;
      final localHigher = local.totalXp > cloudXp;
      if (cloudXp > local.totalXp) {
        local.totalXp = cloudXp;
      }
      local.cloudDirty = localHigher;
      local.lastSyncedAt = DateTime.now().toUtc();
      await _isar.xpIsars.put(local);
    });
  }

  // ─── Daily Activities Sync ──────────────────────────────────────────────────

  Future<void> _syncDailyActivitiesToCloud() async {
    final activities = await _isar.dailyActivityIsars
        .filter()
        .group((q) => q.cloudDirtyEqualTo(true).or().cloudDirtyIsNull())
        .findAll();
    if (activities.isEmpty) return;

    final outbound = activities
        .map(
          (a) => <String, Object?>{
            'day_key': a.dayKey,
            'activity_count': a.activityCount,
          },
        )
        .toList();

    await _supabase.rpc(
      'upsert_daily_activities_batch',
      params: {'p_data': outbound},
    );

    final syncedAt = DateTime.now().toUtc();
    await _isar.writeTxn(() async {
      for (final sent in outbound) {
        final dayKey = sent['day_key']! as int;
        final latest = await _isar.dailyActivityIsars
            .where()
            .dayKeyEqualTo(dayKey)
            .findFirst();
        if (latest == null ||
            !SyncAcknowledgement.matches(
              outbound: sent,
              current: {
                'day_key': latest.dayKey,
                'activity_count': latest.activityCount,
              },
            )) {
          continue;
        }
        latest.cloudDirty = false;
        latest.lastSyncedAt = syncedAt;
        await _isar.dailyActivityIsars.put(latest);
      }
    });
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
            local.cloudDirty = false;
            local.lastSyncedAt = DateTime.now().toUtc();
            await _isar.dailyActivityIsars.put(local);
          }
        } else {
          final newRecord = DailyActivityIsar()
            ..dayKey = dayKey
            ..activityCount = cloudCount
            ..cloudDirty = false
            ..lastSyncedAt = DateTime.now().toUtc();
          await _isar.dailyActivityIsars.put(newRecord);
        }
      }
    });
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _clearLocalUserData({
    String? departingOwnerId,
    bool preservePendingBookmarkRecovery = true,
  }) => _accountDataReset.clearAccountOwnedData(
    departingOwnerId: departingOwnerId,
    preservePendingBookmarkRecovery: preservePendingBookmarkRecovery,
  );

  String? _toDateOnlyString(DateTime? value) =>
      value?.toIso8601String().substring(0, 10);

  // ─── Reading Progress Sync ────────────────────────────────────────────────────

  Future<void> _pullReadingProgressFromCloud(String userId) async {
    final prefs = _prefs;
    if (prefs == null) return;

    final rows = await _supabase
        .from('reading_progress_cloud')
        .select('pages')
        .eq('user_id', userId)
        .maybeSingle();

    if (rows == null) return;

    final cloudPages = (rows['pages'] as List<dynamic>)
        .whereType<int>()
        .where((p) => p >= 1 && p <= 604)
        .toSet();

    if (cloudPages.isEmpty) return;

    // Union merge: combine local + cloud (monotonic, no clobber)
    final raw = prefs.getString('read_pages');
    final localPages = <int>{};
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>).whereType<int>();
        localPages.addAll(list);
      } catch (_) {}
    }

    final merged = {...localPages, ...cloudPages}.toList()..sort();
    await prefs.setString('read_pages', jsonEncode(merged));
    // Not dirty after pull (cloud already has this data)
    // but if local had more pages than cloud, keep dirty so push runs next
    final hadExtra = localPages.any((p) => !cloudPages.contains(p));
    if (!hadExtra) {
      await prefs.remove(ProgressLocalDatasourceImpl.kReadPagesCloudDirty);
    }

    TaliaLogger.i('Reading progress pull: merged ${merged.length} pages');
  }

  Future<void> _pushReadingProgressToCloud() async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (prefs.getBool(ProgressLocalDatasourceImpl.kReadPagesCloudDirty) !=
        true) {
      return;
    }

    final raw = prefs.getString('read_pages');
    if (raw == null) return;

    final List<int> pages;
    try {
      pages = (jsonDecode(raw) as List<dynamic>).whereType<int>().toList();
    } catch (_) {
      return;
    }

    if (pages.isEmpty) return;

    final outbound = <String, Object?>{'pages': _canonicalPages(pages)};

    await _supabase.rpc(
      'upsert_reading_progress',
      params: {'p_pages': outbound['pages']},
    );
    final latestRaw = prefs.getString('read_pages');
    final latestPages = _readCanonicalPages(latestRaw);
    if (SyncAcknowledgement.matches(
      outbound: outbound,
      current: {'pages': latestPages},
    )) {
      await prefs.remove(ProgressLocalDatasourceImpl.kReadPagesCloudDirty);
    }
    TaliaLogger.i('Reading progress pushed: ${pages.length} pages');
  }

  List<int> _canonicalPages(Iterable<int> pages) =>
      pages.where((page) => page >= 1 && page <= 604).toSet().toList()..sort();

  List<int> _readCanonicalPages(String? raw) {
    if (raw == null) return const [];
    try {
      return _canonicalPages(
        (jsonDecode(raw) as List<dynamic>).whereType<int>(),
      );
    } catch (_) {
      return const [];
    }
  }

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
