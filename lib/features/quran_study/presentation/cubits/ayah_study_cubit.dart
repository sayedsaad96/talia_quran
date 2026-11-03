import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/study_entry.dart';
import '../../domain/usecases/get_ayah_study.dart';
import 'ayah_study_state.dart';

class AyahStudyCubit extends Cubit<AyahStudyState> {
  AyahStudyCubit(this.getAyahStudy)
    : super(const AyahStudyState(kind: StudyKind.tafsir));
  final GetAyahStudy getAyahStudy;
  int _generation = 0;
  Future<void> load({
    required int surahId,
    required int ayahNumber,
    required StudyKind kind,
  }) async {
    final generation = ++_generation;
    emit(AyahStudyState(kind: kind, loading: true));
    try {
      final result = await getAyahStudy(
        surahId: surahId,
        ayahNumber: ayahNumber,
        kind: kind,
      );
      if (!isClosed && generation == _generation) {
        emit(AyahStudyState(kind: kind, result: result));
      }
    } catch (_) {
      if (!isClosed && generation == _generation) {
        emit(
          AyahStudyState(
            kind: kind,
            result: StudyLoadResult(StudyLoadStatus.invalidBundle),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }
}
