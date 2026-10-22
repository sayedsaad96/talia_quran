import 'dart:io';

const similarAyahDraftOutputRoot = 'build/similar_ayah_drafts';

String parseSimilarAyahDraftOutput(List<String> arguments) {
  if (arguments.length != 2 || arguments.first != '--output') {
    throw ArgumentError(
      'Usage: dart run tool/build_similar_ayah_index.dart --output <draft-path>',
    );
  }
  final requested = arguments.last.trim();
  if (requested.isEmpty || !_isDraftFile(requested) || _exists(requested)) {
    throw ArgumentError('An explicit new draft output path is required.');
  }
  return requested;
}

Future<void> writeNewSimilarAyahDraft({
  required String outputPath,
  required List<int> bytes,
}) async {
  final output = File(outputPath);
  if (!_isDraftFile(outputPath) || _exists(outputPath)) {
    throw ArgumentError('Draft output path is invalid or already exists.');
  }
  final root = Directory(similarAyahDraftOutputRoot);
  await root.create(recursive: true);
  _verifyRoot(root);
  if (_exists(outputPath)) {
    throw StateError('Draft output appeared before write.');
  }
  await output.writeAsBytes(bytes, flush: true);
}

bool _isDraftFile(String requested) {
  final candidate = File(requested);
  return _samePath(candidate.parent.path, similarAyahDraftOutputRoot) &&
      candidate.uri.pathSegments.last.endsWith('.json');
}

bool _exists(String path) =>
    FileSystemEntity.typeSync(path, followLinks: false) !=
    FileSystemEntityType.notFound;

void _verifyRoot(Directory root) {
  final resolved = Directory(root.resolveSymbolicLinksSync());
  if (!_samePath(resolved.path, similarAyahDraftOutputRoot)) {
    throw StateError('Draft output root must not be a link.');
  }
}

bool _samePath(String first, String second) =>
    _canonicalPath(first) == _canonicalPath(second);

String _canonicalPath(String path) =>
    File(path).absolute.uri.normalizePath().toFilePath().toLowerCase();
