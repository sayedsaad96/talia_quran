part of 'group_khatmah_repository_impl.dart';

extension _GroupKhatmahWatch on GroupKhatmahRepositoryImpl {
  Stream<List<GroupKhatmah>> _watchMine() => Stream.multi((controller) {
    var cancelled = false;
    void emit() {
      if (cancelled) return;
      if (!_allowed) {
        controller.add(const []);
        return;
      }
      try {
        final scope = _scope();
        final state = _cache.read(scope.ownerId);
        controller.add(
          List.unmodifiable(
            state.groups.values.map(
              (g) => _merge.overlay(g, state.intents, scope.ownerId),
            ),
          ),
        );
      } catch (_) {
        controller.add(const []);
      }
    }

    final accountSub = _barrier.changes.listen((_) => emit());
    final audienceSub = _environment.changes.listen((_) => emit());
    Future<void> cancel(bool notify) async {
      if (cancelled) return;
      if (notify) {
        controller.add(const []);
        unawaited(controller.close());
      }
      cancelled = true;
      _watchCancels.remove(cancel);
      await accountSub.cancel();
      await audienceSub.cancel();
    }

    _watchCancels.add(cancel);
    controller.onCancel = () => cancel(false);
    emit();
  });
}
