import '../../domain/repositories/reading_checkpoint_repository.dart';

typedef ReadingCheckpointRpc =
    Future<dynamic> Function(String name, {Map<String, dynamic>? params});

/// Strictly decodes the additive RPCs; malformed responses never acknowledge a write.
class ReadingCheckpointRemoteAdapter implements ReadingCheckpointRemote {
  const ReadingCheckpointRemoteAdapter(this.rpc);
  final ReadingCheckpointRpc rpc;

  RemoteCheckpoint _checkpoint(Map<dynamic, dynamic> json) {
    final page = json['page_number'];
    final revision = json['revision'];
    if (page is! int ||
        page < 1 ||
        page > 604 ||
        revision is! int ||
        revision < 1) {
      throw const FormatException('Invalid remote checkpoint');
    }
    return RemoteCheckpoint(page, revision);
  }

  @override
  Future<RemoteCheckpoint?> get({required String expectedOwnerId}) async {
    final result = await rpc(
      'get_quran_reading_checkpoint',
      params: {'p_expected_owner': expectedOwnerId},
    );
    if (result == null) return null;
    if (result is! Map) {
      throw const FormatException('Invalid remote checkpoint');
    }
    return _checkpoint(result);
  }

  @override
  Future<CheckpointRemoteResult> put({
    required String expectedOwnerId,
    required int pageNumber,
    required int expectedRevision,
    required String mutationId,
  }) async {
    final result = await rpc(
      'put_quran_reading_checkpoint',
      params: {
        'p_expected_owner': expectedOwnerId,
        'p_page': pageNumber,
        'p_expected_revision': expectedRevision,
        'p_mutation_id': mutationId,
      },
    );
    if (result is! Map) {
      throw const FormatException('Invalid checkpoint response');
    }
    final status = result['status'];
    if (status == 'accepted') {
      final value = _checkpoint(result);
      if (value.pageNumber != pageNumber ||
          value.revision != expectedRevision + 1) {
        throw const FormatException('Invalid checkpoint acknowledgement');
      }
      return CheckpointRemoteResult.accepted(value);
    }
    if (status == 'conflict') {
      if (result['revision'] == 0 && result['page_number'] == null) {
        return const CheckpointRemoteResult.conflict(null);
      }
      return CheckpointRemoteResult.conflict(_checkpoint(result));
    }
    throw const FormatException('Unknown checkpoint response');
  }
}
