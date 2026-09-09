enum HomeSlotKind {
  fridayKahf,
  ramadan,
  lastTenNights,
  streakRisk,
  khatmahNearComplete,
  weeklyReflection,
  parentTools,
  signIn,
  tutorial,
}

class HomeSlotCandidate {
  const HomeSlotCandidate({
    required this.kind,
    required this.route,
    this.priority = 0,
  });

  final HomeSlotKind kind;
  final String route;
  final int priority;
}

class HomeContextualSlotSelector {
  const HomeContextualSlotSelector();

  HomeSlotCandidate? select(
    Iterable<HomeSlotCandidate> candidates, {
    required bool Function(HomeSlotKind kind) isSnoozed,
  }) {
    final open = candidates.where((c) => !isSnoozed(c.kind)).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    if (open.isEmpty) return null;
    return open.first;
  }
}
