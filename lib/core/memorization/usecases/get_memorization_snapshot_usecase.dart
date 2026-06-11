import 'package:dartz/dartz.dart';

import '../../error/app_failure.dart';
import '../../utils/usecase.dart';
import '../memorization_progress_reader.dart';
import '../memorization_snapshot.dart';

class GetMemorizationSnapshotUsecase
    implements UseCaseNoParams<MemorizationSnapshot> {
  const GetMemorizationSnapshotUsecase(this._reader);

  final MemorizationProgressReader _reader;

  @override
  Future<Either<Failure, MemorizationSnapshot>> call() =>
      _reader.readSnapshot();
}
