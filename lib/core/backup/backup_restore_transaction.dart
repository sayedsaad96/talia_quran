part of 'backup_restorer.dart';

/// The journaled write phase of [BackupRestorer.restore].
extension _RestoreTransaction on BackupRestorer {
  /// Entries for the v5 bookmark section, resolved from the bundled corpus
  /// before anything is written. Empty when the file or the device does not
  /// carry bookmarks.
  Future<List<BookmarkEntry>> _resolveBookmarks(
    int schemaVersion,
    ParsedBackupSections parsed,
  ) async {
    final reading = _reading;
    if (schemaVersion < 5 || reading == null) return const [];
    return reading.resolve(parsed.bookmarks);
  }

  Future<void> _restoreStores(
    String ownerId,
    ParsedBackupSections parsed,
    int schemaVersion,
    List<BookmarkEntry> bookmarkEntries,
  ) {
    final carriesBookmarks = schemaVersion >= 5 && _reading != null;
    return AccountDataBarrier.forPreferences(_prefs).run((lease) async {
      Future<void> work(BookmarkRestoreAccess? bookmarks) => _journaledWrite(
        ownerId,
        lease,
        parsed,
        schemaVersion,
        bookmarkEntries,
        bookmarks,
      );
      final reading = _reading;
      if (!carriesBookmarks || reading == null) return work(null);
      return reading.runBookmarkRestore(ownerId, work);
    });
  }

  Future<void> _journaledWrite(
    String ownerId,
    AccountDataLease lease,
    ParsedBackupSections parsed,
    int schemaVersion,
    List<BookmarkEntry> bookmarkEntries,
    BookmarkRestoreAccess? bookmarks,
  ) async {
    _ensureOwner(ownerId);
    await _ensureMaintenanceAdmission();
    final ticket = await _journal.prepare(
      destinationOwner: ownerId,
      snapshots: {
        RestorePart.isar: await RestoreIsarSnapshot(_isar).capture(ownerId),
        RestorePart.prefs: RestorePreferencesSnapshot(
          _prefs,
        ).capture(_touchedKeys(parsed, ownerId)),
        if (bookmarks != null) RestorePart.bookmarks: await bookmarks.capture(),
      },
    );
    try {
      _ensureOwner(ownerId);
      await _ensureMaintenanceAdmission();
      await _replaceIsar(parsed, ownerId, schemaVersion);
      _ensureOwner(ownerId);
      lease.check();
      await _ensureMaintenanceAdmission();
      await _replacePreferences(parsed, ownerId, lease);
      await bookmarks?.addMissing(bookmarkEntries);
      _ensureOwner(ownerId);
      await _ensureMaintenanceAdmission();
    } on _RestoreAdmissionLost {
      // Another writer could now be admitted. Preserve the prepared journal
      // for a genuinely exclusive restart; rollback here would also race.
      _gate.blockUntilRecovered('maintenance_admission_lost');
      rethrow;
    } catch (_) {
      await _abandon(ticket, ownerId, bookmarks);
      rethrow;
    }
    await _commitAndClean(ticket);
  }

  Future<void> _commitAndClean(RestoreTicket ticket) async {
    try {
      await _journal.markCommitted(ticket);
    } catch (_) {
      // The commit may be durable even if its read-back failed. Do not roll
      // back underneath it; recovery decides from durable state on restart.
      _gate.blockUntilRecovered('commit_unconfirmed');
      rethrow;
    }
    try {
      await _journal.complete(ticket);
    } on RestoreJournalCleanupPending {
      // The data decision is final; startup recovery finishes the deletion.
      TaliaLogger.w('Restore journal cleanup is pending');
    }
  }

  /// Puts every store back from the journal while the owner is unchanged.
  /// After an owner switch nothing is put back: restoring the previous owner's
  /// unscoped data would hand it to the new account, and the switch's reset
  /// owns the cleanup. The journal then records a durable abort instead.
  Future<void> _abandon(
    RestoreTicket ticket,
    String ownerId,
    BookmarkRestoreAccess? bookmarks,
  ) async {
    try {
      if (_owner.currentOwnerId == ownerId) {
        await _ensureMaintenanceAdmission();
        await _journal.rollback(
          ticket,
          RestoreStoreRollbacks(
            _isar,
            _prefs,
            _reading,
            heldBookmarks: bookmarks,
          ).registry,
        );
      } else {
        await _journal.abortForOwner(ownerId);
      }
    } catch (e, st) {
      // The journal stays `prepared`, so the next startup retries the
      // rollback; until then no further restore may start.
      TaliaLogger.e('Backup restore rollback failed', e, st);
      _gate.blockUntilRecovered('rollback_failed');
    }
  }
}
