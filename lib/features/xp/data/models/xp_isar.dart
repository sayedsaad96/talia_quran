import 'package:isar/isar.dart';
part 'xp_isar.g.dart';

@collection
class XpIsar {
  // id ثابت = 1 — سجل واحد فقط
  Id id = 1;
  int totalXp = 0;

  /// Null on legacy rows is treated as dirty until first successful cloud push.
  bool? cloudDirty;

  DateTime? lastSyncedAt;
}
