part of 'surah_list_cubit.dart';

@immutable
abstract class SurahListState extends Equatable {
  const SurahListState();
  @override
  List<Object?> get props => [];
}

class SurahListInitial extends SurahListState {
  const SurahListInitial();
}

class SurahListLoading extends SurahListState {
  const SurahListLoading();
}

class SurahListLoaded extends SurahListState {
  const SurahListLoaded({
    required this.surahs,
    required this.filtered,
    this.query = '',
    this.selectedJuz,
    this.memorizationStatus = const {},
  });

  final List<Surah> surahs;
  final List<Surah> filtered;
  final String query;
  final int? selectedJuz;

  /// Memorization badge per surah id; absent = not started (N17).
  final Map<int, SurahMemorizationStatus> memorizationStatus;

  SurahListLoaded copyWith({
    List<Surah>? surahs,
    List<Surah>? filtered,
    String? query,
    int? selectedJuz,
    Map<int, SurahMemorizationStatus>? memorizationStatus,
  }) => SurahListLoaded(
    surahs: surahs ?? this.surahs,
    filtered: filtered ?? this.filtered,
    query: query ?? this.query,
    selectedJuz: selectedJuz,
    memorizationStatus: memorizationStatus ?? this.memorizationStatus,
  );

  @override
  List<Object?> get props => [
    surahs,
    filtered,
    query,
    selectedJuz,
    memorizationStatus,
  ];
}

class SurahListError extends SurahListState {
  const SurahListError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
