import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_cloud_mappers.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_cloud_sync_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  group('ChildIdentityPolicy', () {
    test('normalizes whitespace and keeps the name otherwise intact', () {
      expect(
        ChildIdentityPolicy.normalizeNickname('  مريم \t  علي '),
        'مريم علي',
      );
      expect(ChildIdentityPolicy.normalizeNickname('Yusuf'), 'Yusuf');
    });

    test('rejects blank, too long and control-character names', () {
      expect(ChildIdentityPolicy.normalizeNickname(null), isNull);
      expect(ChildIdentityPolicy.normalizeNickname('   '), isNull);
      expect(ChildIdentityPolicy.normalizeNickname('a' * 51), isNull);
      expect(ChildIdentityPolicy.normalizeNickname('Ali\u0000'), isNull);
      expect(ChildIdentityPolicy.normalizeNickname('a' * 50), 'a' * 50);
    });

    test('counts code points like Postgres char_length', () {
      // 50 emoji are 100 UTF-16 units but 50 characters on the server.
      expect(ChildIdentityPolicy.normalizeNickname('😀' * 50), '😀' * 50);
      expect(ChildIdentityPolicy.normalizeNickname('😀' * 51), isNull);
    });

    test('accepts only ages 5 to 12', () {
      expect(ChildIdentityPolicy.isValidAge(null), isFalse);
      expect(ChildIdentityPolicy.isValidAge(4), isFalse);
      expect(ChildIdentityPolicy.isValidAge(5), isTrue);
      expect(ChildIdentityPolicy.isValidAge(12), isTrue);
      expect(ChildIdentityPolicy.isValidAge(13), isFalse);
    });

    test('matches the limits enforced by the Supabase migration', () {
      final migration = File(
        'supabase/migrations/20260929195346_guardian_child_identity.sql',
      ).readAsStringSync();
      expect(
        migration,
        contains(
          'char_length(v_name) NOT BETWEEN 1 AND '
          '${ChildIdentityPolicy.maxNicknameLength}',
        ),
      );
      expect(
        migration,
        contains(
          'p_age NOT BETWEEN ${ChildIdentityPolicy.minAge} AND '
          '${ChildIdentityPolicy.maxAge}',
        ),
      );
    });
  });

  test('dashboard payload carries the child age', () {
    final mapper = MemorizationCloudMappers(const ProgressMetricsService());
    final children = mapper.parseRemoteChildrenDashboard([
      {
        'child_user_id': 'child-1',
        'display_name': 'Maryam',
        'child_nickname': 'Maryam',
        'age': 9,
        'logs': <dynamic>[],
        'rewards': <dynamic>[],
      },
      {
        'child_user_id': 'child-2',
        'display_name': 'Older server',
        'logs': <dynamic>[],
        'rewards': <dynamic>[],
      },
    ]);

    expect(children.first.displayName, 'Maryam');
    expect(children.first.childAge, 9);
    expect(children.last.childAge, isNull);
  });

  group('childIdentityUpdateFailure', () {
    String codeFor(String message, {String? code}) =>
        MemorizationKidsCloudSyncService.childIdentityUpdateFailure(
          PostgrestException(message: message, code: code ?? 'P0001'),
        ).message;

    test('maps update_linked_child_identity exceptions', () {
      expect(
        codeFor('No active guardian link for this child'),
        CubitMessageCodes.guardianChildNotLinked,
      );
      expect(
        codeFor('Invalid child nickname'),
        CubitMessageCodes.childNicknameInvalid,
      );
      expect(codeFor('Invalid child age'), CubitMessageCodes.childAgeInvalid);
      expect(
        codeFor('Not authenticated'),
        CubitMessageCodes.guardianSignInRequired,
      );
    });

    test('a server without the function reports the edit as unavailable', () {
      expect(
        codeFor(
          'Could not find the function '
          'public.update_linked_child_identity in the schema cache',
          code: 'PGRST202',
        ),
        CubitMessageCodes.childIdentityUpdateUnavailable,
      );
    });

    test('keeps unknown server errors generic', () {
      expect(codeFor('deadlock detected'), CubitMessageCodes.errorServer);
    });
  });
}
