import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran_study/domain/entities/study_entry.dart';
import 'package:talia_quran/features/quran_study/domain/repositories/quran_study_repository.dart';
import 'package:talia_quran/features/quran_study/domain/usecases/get_ayah_study.dart';
import 'package:talia_quran/features/quran_study/presentation/cubits/ayah_study_cubit.dart';

class FakeRepository implements QuranStudyRepository {
  final requests = <int, Completer<StudyLoadResult>>{};
  @override
  Future<StudyLoadResult> getAyahStudy({
    required int surahId,
    required int ayahNumber,
    required StudyKind kind,
  }) => (requests[ayahNumber] = Completer<StudyLoadResult>()).future;
}

void main() {
  test('late result cannot replace the newer ayah', () async {
    final repo = FakeRepository();
    final cubit = AyahStudyCubit(GetAyahStudy(repo));
    final a = cubit.load(surahId: 1, ayahNumber: 1, kind: StudyKind.tafsir);
    final b = cubit.load(
      surahId: 1,
      ayahNumber: 2,
      kind: StudyKind.meaningTranslation,
    );
    final newer = StudyLoadResult(StudyLoadStatus.ready);
    repo.requests[2]!.complete(newer);
    await b;
    repo.requests[1]!.complete(StudyLoadResult(StudyLoadStatus.unavailable));
    await a;
    expect(cubit.state.kind, StudyKind.meaningTranslation);
    expect(cubit.state.result, same(newer));
    await cubit.close();
  });
}
