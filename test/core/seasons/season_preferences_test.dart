import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/backup/backup_sections.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/core/seasons/season_preferences.dart';
import 'package:talia_quran/features/seasons/domain/last_ten_reminder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SeasonPreferences> build({
    Map<String, Object> values = const {},
    String ownerId = 'user-a',
  }) async {
    SharedPreferences.setMockInitialValues(values);
    return SeasonPreferences(
      await SharedPreferences.getInstance(),
      FixedRecordOwnerProvider(ownerId),
    );
  }

  test('every season defaults on except Monday/Thursday fasting', () async {
    final p = await build();
    for (final id in SeasonId.values) {
      expect(
        p.isSeasonEnabled(id),
        SeasonPreferences.defaultEnabled(id),
        reason: id.name,
      );
    }
    expect(p.isSeasonEnabled(SeasonId.monThu), isFalse);
    expect(p.isSeasonEnabled(SeasonId.ramadan), isTrue);
  });

  test('the master switch hides seasons but keeps their choices', () async {
    final p = await build();
    await p.setSeasonEnabled(SeasonId.ramadan, true);
    await p.setMasterEnabled(false);
    expect(p.masterEnabled, isFalse);
    expect(p.isSeasonVisible(SeasonId.ramadan), isFalse);
    expect(p.isSeasonEnabled(SeasonId.ramadan), isTrue);
    await p.setMasterEnabled(true);
    expect(p.isSeasonVisible(SeasonId.ramadan), isTrue);
  });

  test('hiding one season leaves the others visible', () async {
    final p = await build();
    await p.setSeasonEnabled(SeasonId.ramadan, false);
    expect(p.isSeasonVisible(SeasonId.ramadan), isFalse);
    expect(p.isSeasonVisible(SeasonId.shabanPrep), isTrue);
  });

  test('reminders default off; kids seasons default on', () async {
    final p = await build();
    expect(p.remindersEnabled, isFalse);
    expect(p.kidsSeasonsEnabled, isTrue);
    await p.setRemindersEnabled(true);
    await p.setKidsSeasonsEnabled(false);
    expect(p.remindersEnabled, isTrue);
    expect(p.kidsSeasonsEnabled, isFalse);
  });

  test('the last-ten opt-in no longer implies seasonal reminders', () async {
    final legacy = await build(values: {lastTenReminderPreferenceKey: true});
    expect(legacy.remindersEnabled, isFalse);
    await legacy.setRemindersEnabled(true);
    expect(legacy.remindersEnabled, isTrue);
  });

  test('restore defaults keeps the guardian kids choice', () async {
    final p = await build();
    await p.setKidsSeasonsEnabled(false);
    await p.setMasterEnabled(false);
    await p.setRemindersEnabled(true);
    await p.resetToDefaults();
    expect(p.kidsSeasonsEnabled, isFalse);
    expect(p.masterEnabled, isTrue);
    expect(p.remindersEnabled, isFalse);
  });

  test('wrong-typed stored values fall back to defaults', () async {
    final p = await build(
      values: {
        'season_pref_master|user-a': 'x',
        'season_pref_ramadan|user-a': 1,
        'season_pref_monThu|user-a': 'y',
        'season_pref_reminders|user-a': 'z',
        'season_pref_kids|user-a': 2,
      },
    );
    expect(p.masterEnabled, isTrue);
    expect(p.isSeasonEnabled(SeasonId.ramadan), isTrue);
    expect(p.isSeasonEnabled(SeasonId.monThu), isFalse);
    expect(p.remindersEnabled, isFalse);
    expect(p.kidsSeasonsEnabled, isTrue);
  });

  test('choices are isolated per owner', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferences.getInstance();
    final a = SeasonPreferences(
      store,
      const FixedRecordOwnerProvider('user-a'),
    );
    final b = SeasonPreferences(
      store,
      const FixedRecordOwnerProvider('user-b'),
    );
    await a.setSeasonEnabled(SeasonId.ramadan, false);
    await a.setMasterEnabled(false);
    expect(a.isSeasonVisible(SeasonId.ramadan), isFalse);
    expect(b.isSeasonVisible(SeasonId.ramadan), isTrue);
    expect(b.masterEnabled, isTrue);
  });

  test('season keys enter the backup tokenized and validated as bools', () {
    expect(
      BackupPreferencePolicy.backupKeyFor(
        'season_pref_ramadan|user-a',
        'user-a',
      ),
      'season_pref_ramadan|$kBackupOwnerToken',
    );
    expect(
      BackupPreferencePolicy.backupKeyFor(
        'season_pref_master|user-a',
        'user-a',
      ),
      'season_pref_master|$kBackupOwnerToken',
    );
    expect(
      BackupPreferencePolicy.backupKeyFor(
        'season_pref_ramadan|user-b',
        'user-a',
      ),
      isNull,
    );
    expect(
      BackupPreferencePolicy.restoreKeyFor(
        'season_pref_reminders|$kBackupOwnerToken',
        'user-a',
      ),
      'season_pref_reminders|user-a',
    );
    expect(
      () => BackupPreferencePolicy.validate(
        'season_pref_ramadan|$kBackupOwnerToken',
        3,
      ),
      throwsA(isA<BackupSectionInvalid>()),
    );
  });
}
