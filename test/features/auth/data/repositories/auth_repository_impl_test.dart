import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';
import 'package:talia_quran/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:talia_quran/features/hifz/data/models/isar_ayah_progress.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/streak/data/models/daily_activity_isar.dart';
import 'package:talia_quran/features/streak/data/models/streak_isar.dart';
import 'package:talia_quran/features/xp/data/models/xp_isar.dart';

bool _isarCoreInitialized = false;

Future<void> _initializeIsarCoreForTests() async {
  if (_isarCoreInitialized) return;
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final dllPath =
          '$localAppData\\Pub\\Cache\\hosted\\pub.dev\\'
          'isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
      if (File(dllPath).existsSync()) {
        await Isar.initializeIsarCore(libraries: {Abi.current(): dllPath});
        _isarCoreInitialized = true;
        return;
      }
    }
  }
  await Isar.initializeIsarCore();
  _isarCoreInitialized = true;
}

void main() {
  group('AuthRepositoryImpl offline auth behavior', () {
    late SharedPreferences prefs;
    late Isar isar;
    late Directory dir;
    late AuthRepositoryImpl repository;

    setUp(() async {
      await _initializeIsarCoreForTests();
      SharedPreferences.setMockInitialValues({
        'user_profile': '{"name":"Signed In User","age":null}',
        'read_pages': <String>['1', '2'],
        'bookmarks': 'local-bookmarks',
        'mem_plus_profile': '{"selectedPath":"adult"}',
        'theme_mode': 'dark',
        'locale': 'ar',
      });
      prefs = await SharedPreferences.getInstance();
      dir = await Directory.systemTemp.createTemp('talia_auth_repo_');
      isar = await Isar.open(
        [
          IsarAyahProgressSchema,
          IsarAyahReviewRecordSchema,
          IsarV2SessionSchema,
          StreakIsarSchema,
          XpIsarSchema,
          DailyActivityIsarSchema,
          CloudSyncQueueItemSchema,
        ],
        directory: dir.path,
        name: 'auth_repo_',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      repository = AuthRepositoryImpl(
        isar,
        AccountDataReset(isar, prefs),
      );
    });

    test(
      'signOut clears account-owned data when Supabase is not initialized',
      () async {
        final result = await repository.signOut();

        expect(result, const Right(unit));
        expect(prefs.getString('user_profile'), isNull);
        expect(prefs.getStringList('read_pages'), isNull);
        expect(prefs.getString('mem_plus_profile'), isNull);
        expect(prefs.getString('bookmarks'), 'local-bookmarks');
        expect(prefs.getString('theme_mode'), 'dark');
        expect(prefs.getString('locale'), 'ar');
      },
    );

    test(
      'deleteAccount fails safely offline without clearing local data',
      () async {
        final result = await repository.deleteAccount();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthConfigurationFailure>()),
          (_) =>
              fail('Expected deleteAccount to fail when Supabase is offline'),
        );
        expect(prefs.getString('user_profile'), isNotNull);
        expect(prefs.getStringList('read_pages'), <String>['1', '2']);
        expect(prefs.getString('bookmarks'), 'local-bookmarks');
        expect(prefs.getString('mem_plus_profile'), '{"selectedPath":"adult"}');
      },
    );
  });
}
