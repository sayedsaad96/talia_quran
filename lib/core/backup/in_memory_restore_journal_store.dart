import '../security/encrypted_account_preferences_store.dart';

/// A volatile [EncryptedAccountPreferencesStore] for a restore journal.
///
/// It survives nothing: a process death loses the journal, so restores backed
/// by it are only as safe as an in-process rollback. Production wiring must
/// pass the platform-backed store; this exists for tests and tooling.
class InMemoryRestoreJournalStore implements EncryptedAccountPreferencesStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String ownerId, String key) async =>
      _values['$ownerId/$key'];

  @override
  Future<void> write(String ownerId, String key, String value) async {
    _values['$ownerId/$key'] = value;
  }

  @override
  Future<void> delete(String ownerId, String key) async {
    _values.remove('$ownerId/$key');
  }
}
