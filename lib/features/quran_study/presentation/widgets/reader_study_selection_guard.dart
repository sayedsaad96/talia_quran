/// Invalidates outstanding selections whenever a newer selection starts or
/// the reader changes page, including an A → B → A page transition.
class ReaderStudySelectionGuard {
  int _generation = 0;

  ({int generation, int page}) begin(int page) =>
      (generation: ++_generation, page: page);

  void invalidate() => _generation++;

  bool isCurrent(
    ({int generation, int page}) token, {
    required int? currentPage,
  }) => token.generation == _generation && token.page == currentPage;

  Future<T?> resolve<T>(
    ({int generation, int page}) token,
    Future<T> operation, {
    required int? Function() currentPage,
  }) async {
    final result = await operation;
    return isCurrent(token, currentPage: currentPage()) ? result : null;
  }
}
