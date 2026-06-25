import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  group('AuthRepositoryImpl offline auth behavior', () {
    late SharedPreferences prefs;
    late AuthRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'user_profile': '{"name":"Signed In User","age":null}',
        'read_pages': <String>['1', '2'],
        'bookmarks': 'local-bookmarks',
        'mem_plus_profile': '{"selectedPath":"adult"}',
        'theme_mode': 'dark',
        'locale': 'ar',
      });
      prefs = await SharedPreferences.getInstance();
      repository = AuthRepositoryImpl(_MockIsar(), prefs);
    });

    test(
      'signOut succeeds as a no-op when Supabase is not initialized',
      () async {
        final result = await repository.signOut();

        expect(result, const Right(unit));
        expect(prefs.getString('user_profile'), isNotNull);
        expect(prefs.getStringList('read_pages'), <String>['1', '2']);
        expect(prefs.getString('bookmarks'), 'local-bookmarks');
        expect(prefs.getString('mem_plus_profile'), '{"selectedPath":"adult"}');
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

class _MockIsar extends Mock implements Isar {}
