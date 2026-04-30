import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkEntry {
  const BookmarkEntry({
    required this.surahId,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
    required this.savedAt,
  });

  final int surahId;
  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'surahId': surahId,
        'surahName': surahName,
        'ayahNumber': ayahNumber,
        'ayahText': ayahText,
        'savedAt': savedAt.toIso8601String(),
      };

  factory BookmarkEntry.fromJson(Map<String, dynamic> json) => BookmarkEntry(
        surahId: json['surahId'] as int,
        surahName: json['surahName'] as String,
        ayahNumber: json['ayahNumber'] as int,
        ayahText: json['ayahText'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
      );

  String get key => '${surahId}_$ayahNumber';
}

class BookmarkService extends ChangeNotifier {
  BookmarkService(this._prefs);
  final SharedPreferences _prefs;

  static const _storageKey = 'quran_bookmarks';

  List<BookmarkEntry> getAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => BookmarkEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (_) {
      return [];
    }
  }

  bool isBookmarked(int surahId, int ayahNumber) {
    return getAll().any(
        (b) => b.surahId == surahId && b.ayahNumber == ayahNumber);
  }

  Future<void> toggle(BookmarkEntry entry) async {
    final all = getAll();
    final exists =
        all.any((b) => b.surahId == entry.surahId && b.ayahNumber == entry.ayahNumber);
    if (exists) {
      all.removeWhere(
          (b) => b.surahId == entry.surahId && b.ayahNumber == entry.ayahNumber);
    } else {
      all.insert(0, entry);
    }
    await _prefs.setString(
      _storageKey,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> clear() async {
    await _prefs.remove(_storageKey);
    notifyListeners();
  }
}
