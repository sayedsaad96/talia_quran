import '../entities/khatmah_history_entry.dart';
import '../repositories/khatmah_repository.dart';

class GetKhatmahHistoryUsecase {
  const GetKhatmahHistoryUsecase(this._repository);

  final KhatmahRepository _repository;

  Stream<void>? get changes => _repository.changes;

  Future<List<KhatmahHistoryEntry>> call() => _repository.getHistory();
}
