import 'package:isar/isar.dart';
import '../../domain/entities/hifz_entities.dart';
import 'ayah_progress_model.dart';

part 'isar_ayah_progress.g.dart';

@collection
class IsarAyahProgress {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String compositeKey; // surahId_ayahNumber

  late int surahId;
  late int ayahNumber;
  
  @enumerated
  late AyahStatus status;
  
  late int repetitions;
  late DateTime nextReviewDate;
  late DateTime lastReviewDate;

  // Conversion methods
  AyahProgressModel toModel() {
    return AyahProgressModel(
      surahId: surahId,
      ayahNumber: ayahNumber,
      status: status,
      repetitions: repetitions,
      nextReviewDate: nextReviewDate,
      lastReviewDate: lastReviewDate,
    );
  }

  static IsarAyahProgress fromModel(AyahProgressModel model) {
    return IsarAyahProgress()
      ..compositeKey = '${model.surahId}_${model.ayahNumber}'
      ..surahId = model.surahId
      ..ayahNumber = model.ayahNumber
      ..status = model.status
      ..repetitions = model.repetitions
      ..nextReviewDate = model.nextReviewDate
      ..lastReviewDate = model.lastReviewDate;
  }
}
