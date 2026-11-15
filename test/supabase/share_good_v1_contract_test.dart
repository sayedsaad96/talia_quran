import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _tables = [
  'invites',
  'invite_identities',
  'participations',
  'completion_disclosures',
  'rate_limits',
];

const _operations = {
  'create_share_good_invite_v1': 'share_good_create_invite_v1',
  'create_share_good_chain_invite_v1': 'share_good_create_chain_invite_v1',
  'resolve_share_good_invite_v1': 'share_good_resolve_invite_v1',
  'advance_share_good_participation_v1': 'share_good_advance_participation_v1',
  'disclose_share_good_completion_v1': 'share_good_disclose_completion_v1',
  'get_share_good_impact_v1': 'share_good_get_impact_v1',
};

void main() {
  late String migration;

  setUpAll(() {
    final file = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .singleWhere((file) => file.path.endsWith('_share_good_v1.sql'));
    migration = file
        .readAsStringSync()
        .replaceAll(RegExp(r'--[^\r\n]*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  });

  test('Share Good tables have RLS and revoke all client privileges', () {
    for (final name in _tables) {
      final table = 'public.share_good_$name';
      expect(migration, contains('create table if not exists $table'));
      expect(
        migration,
        contains('alter table $table enable row level security'),
      );
      final revoke = RegExp(
        'revoke all on table $table from ([^;]+);',
      ).firstMatch(migration);
      expect(
        revoke?.group(1)?.split(',').map((role) => role.trim()),
        unorderedEquals(['public', 'anon', 'authenticated', 'service_role']),
        reason: table,
      );
    }
    expect(
      migration,
      isNot(matches(r'grant [^;]+ on (?:table )?public\.share_good_')),
    );
  });

  test(
    'six invoker wrappers call private definers with empty search paths',
    () {
      for (final entry in _operations.entries) {
        final wrapper = _function(migration, 'public.${entry.key}');
        final helper = _function(migration, 'private.${entry.value}');
        expect(wrapper, contains('security invoker'));
        expect(wrapper, contains("set search_path = ''"));
        expect(wrapper, contains('private.${entry.value}('));
        expect(helper, contains('security definer'));
        expect(helper, contains("set search_path = ''"));
      }
    },
  );

  test('only the two guest operations grant anon execution', () {
    final grants = <String, Set<String>>{};
    for (final match in RegExp(
      r'grant execute on function ([\w.]+)\([^)]*\) to ([^;]+);',
    ).allMatches(migration)) {
      final function = match.group(1)!;
      grants
          .putIfAbsent(function, () => {})
          .addAll(match.group(2)!.split(',').map((role) => role.trim()));
    }
    expect(
      grants.keys,
      unorderedEquals([
        ..._operations.keys.map((name) => 'public.$name'),
        ..._operations.values.map((name) => 'private.$name'),
      ]),
    );
    for (final grant in grants.entries) {
      final guest =
          grant.key.contains('resolve') || grant.key.contains('advance');
      expect(
        grant.value,
        unorderedEquals(['authenticated', if (guest) 'anon']),
      );
    }
    expect(migration, isNot(contains('all functions in schema')));
    final config = File('supabase/config.toml').readAsStringSync();
    final schemas = RegExp(
      r'^schemas\s*=\s*\[([^\]]*)\]',
      multiLine: true,
    ).firstMatch(config)?.group(1);
    expect(schemas, isNotNull);
    expect(schemas, isNot(contains('"private"')));
  });

  test('deletion preserves invites and removes identity disclosures', () {
    expect(
      migration,
      matches(
        r'creator_user_id uuid[^,]*references auth\.users\s*\([^)]*\) on delete set null',
      ),
    );
    expect(
      RegExp(
        r'\buser_id uuid[^,]*references auth\.users\s*\([^)]*\) on delete cascade',
      ).allMatches(migration),
      hasLength(2),
    );
    expect(migration, isNot(contains('function public.delete_current_user')));
  });

  test('ordinary advance has an allowlist and impact omits bearer tokens', () {
    final advance = _function(
      migration,
      'private.share_good_advance_participation_v1',
    );
    expect(
      advance,
      matches(r"'opened'\s*,\s*'started'\s*,\s*'completed_private'"),
    );
    final impact = _function(migration, 'private.share_good_get_impact_v1');
    for (final field in [
      'token',
      'token_hash',
      'creator_user_id',
      'participant_key_hash',
    ]) {
      expect(impact, isNot(contains("'$field'")));
    }
  });
}

String _function(String sql, String name) {
  final match = RegExp(
    'create (?:or replace )?function ${RegExp.escape(name)}\\s*\\(.*?'
    r'\bas\s+(\$\w*\$).*?\1\s*;',
  ).firstMatch(sql);
  expect(match, isNotNull, reason: name);
  return match!.group(0)!;
}
