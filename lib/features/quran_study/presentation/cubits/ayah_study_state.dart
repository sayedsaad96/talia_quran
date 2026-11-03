import '../../domain/entities/study_entry.dart';

class AyahStudyState {
  const AyahStudyState({required this.kind, this.loading = false, this.result});
  final StudyKind kind;
  final bool loading;
  final StudyLoadResult? result;
}
