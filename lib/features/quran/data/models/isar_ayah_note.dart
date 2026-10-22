import 'package:isar_community/isar.dart';

part 'isar_ayah_note.g.dart';

/// Owner-scoped, local-only note storage.
@collection
class IsarAyahNote {
  Id id = Isar.autoIncrement;

  @Index(
    unique: true,
    replace: true,
    composite: [CompositeIndex('surahId'), CompositeIndex('ayahNumber')],
  )
  late String ownerId;

  late int surahId;
  late int ayahNumber;
  late String body;
  late DateTime createdAt;
  late DateTime updatedAt;
}
