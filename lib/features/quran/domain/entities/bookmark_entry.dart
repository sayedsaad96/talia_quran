class BookmarkEntry {
  const BookmarkEntry({
    required this.surahId,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
    required this.savedAt,
    this.revision = 0,
    this.isDeleted = false,
    this.isSynced = false,
  });

  final int surahId;
  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final DateTime savedAt;
  final int revision;
  final bool isDeleted;
  final bool isSynced;

  Map<String, dynamic> toJson() => {
        'surahId': surahId,
        'surahName': surahName,
        'ayahNumber': ayahNumber,
        'ayahText': ayahText,
        'savedAt': savedAt.toIso8601String(),
        'revision': revision,
        'isDeleted': isDeleted,
        'isSynced': isSynced,
      };

  factory BookmarkEntry.fromJson(Map<String, dynamic> json) => BookmarkEntry(
        surahId: json['surahId'] as int,
        surahName: json['surahName'] as String,
        ayahNumber: json['ayahNumber'] as int,
        ayahText: json['ayahText'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        revision: json['revision'] as int? ?? 0,
        isDeleted: json['isDeleted'] as bool? ?? false,
        isSynced: json['isSynced'] as bool? ?? false,
      );

  BookmarkEntry copyWith({
    int? revision,
    bool? isDeleted,
    bool? isSynced,
  }) => BookmarkEntry(
    surahId: surahId,
    surahName: surahName,
    ayahNumber: ayahNumber,
    ayahText: ayahText,
    savedAt: savedAt,
    revision: revision ?? this.revision,
    isDeleted: isDeleted ?? this.isDeleted,
    isSynced: isSynced ?? this.isSynced,
  );

  String get key => '${surahId}_$ayahNumber';
}
