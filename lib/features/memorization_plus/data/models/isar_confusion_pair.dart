import 'package:isar_community/isar.dart';

part 'isar_confusion_pair.g.dart';

/// Local-only, adult directed aggregate of a confirmed failed attempt.
@collection
class IsarConfusionPair {
  Id id = Isar.autoIncrement;

  @Index(
    unique: true,
    replace: true,
    composite: [CompositeIndex('targetKey'), CompositeIndex('otherKey')],
  )
  late String ownerId;

  /// Fixed to [adultAudience]; kept explicit to reject accidental mixed data.
  late String audience;
  late String targetKey;
  late String otherKey;
  late int count;
  late DateTime firstAt;
  late DateTime lastAt;

  static const adultAudience = 'adult';
}
