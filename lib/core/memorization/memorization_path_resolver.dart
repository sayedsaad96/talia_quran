import 'dart:async';

import '../../features/memorization_plus/domain/entities/memorization_profile.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';

class MemorizationPathResolver {
  MemorizationPathResolver(this._repository);

  final MemorizationPlusRepository _repository;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  Future<MemorizationProfile?> currentProfile() async {
    final result = await _repository.getMemorizationProfile();
    return result.fold((_) => null, (profile) => profile);
  }

  bool isKids(MemorizationProfile? profile) => profile?.isChild == true;

  bool isAdult(MemorizationProfile? profile) => profile?.isAdult == true;

  void notifyChanged() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  Future<void> dispose() => _changes.close();
}
