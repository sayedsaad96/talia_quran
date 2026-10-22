import '../entities/ayah_note.dart';

abstract interface class AyahNoteRepository {
  Future<AyahNote?> get(int surahId, int ayahNumber);
  Future<List<AyahNote>> listAll();
  Future<AyahNote> upsert(int surahId, int ayahNumber, String body);
  Future<void> delete(int surahId, int ayahNumber);
}

/// Optional capability: move notes written as a guest to the signed-in owner.
abstract interface class AyahNoteClaimer {
  /// Returns how many guest notes were merged into the current owner.
  Future<int> claimLocalNotes();
}
