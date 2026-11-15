import 'package:equatable/equatable.dart';
import '../../../azkar/domain/entities/azkar_entities.dart';

sealed class InviteActivityTarget extends Equatable {
  const InviteActivityTarget();
  Map<String, Object> toJson();
  static InviteActivityTarget fromJson(Object? json) {
    if (json is! Map || json['v'] is! int || json['v'] != 1) {
      throw const FormatException('Invalid target');
    }
    bool keys(Set<String> expected) =>
        json.length == expected.length && json.keys.every(expected.contains);
    bool page(Object? n) => n is int && n >= 1 && n <= 604;
    switch (json['type']) {
      case 'quran_page':
        if (keys({'v', 'type', 'page'}) && page(json['page'])) {
          return QuranPageInviteTarget(json['page'] as int);
        }
      case 'quran_surah':
        final id = json['surah_id'];
        if (keys({'v', 'type', 'surah_id'}) &&
            id is int &&
            id >= 1 &&
            id <= 114) {
          return QuranSurahInviteTarget(id);
        }
      case 'quran_wird':
        final start = json['start_page'];
        final end = json['end_page'];
        if (keys({'v', 'type', 'start_page', 'end_page'}) &&
            page(start) &&
            page(end) &&
            (start as int) <= (end as int) &&
            end - start <= 19) {
          return QuranWirdInviteTarget(start, end);
        }
      case 'azkar_collection':
        if (keys({'v', 'type', 'category'})) {
          if (json['category'] == 'morning') {
            return const AzkarCollectionInviteTarget(AzkarCategory.morning);
          }
          if (json['category'] == 'evening') {
            return const AzkarCollectionInviteTarget(AzkarCategory.evening);
          }
        }
    }
    throw const FormatException('Invalid target');
  }
}

final class QuranPageInviteTarget extends InviteActivityTarget {
  const QuranPageInviteTarget(this.pageNumber)
    : assert(pageNumber >= 1 && pageNumber <= 604);
  final int pageNumber;
  @override
  Map<String, Object> toJson() => {
    'v': 1,
    'type': 'quran_page',
    'page': pageNumber,
  };
  @override
  List<Object?> get props => [pageNumber];
}

final class QuranSurahInviteTarget extends InviteActivityTarget {
  const QuranSurahInviteTarget(this.surahId)
    : assert(surahId >= 1 && surahId <= 114);
  final int surahId;
  @override
  Map<String, Object> toJson() => {
    'v': 1,
    'type': 'quran_surah',
    'surah_id': surahId,
  };
  @override
  List<Object?> get props => [surahId];
}

final class QuranWirdInviteTarget extends InviteActivityTarget {
  const QuranWirdInviteTarget(this.startPage, this.endPage)
    : assert(
        startPage >= 1 &&
            endPage <= 604 &&
            startPage <= endPage &&
            endPage - startPage <= 19,
      );
  final int startPage, endPage;
  @override
  Map<String, Object> toJson() => {
    'v': 1,
    'type': 'quran_wird',
    'start_page': startPage,
    'end_page': endPage,
  };
  @override
  List<Object?> get props => [startPage, endPage];
}

final class AzkarCollectionInviteTarget extends InviteActivityTarget {
  const AzkarCollectionInviteTarget(this.category)
    : assert(
        category == AzkarCategory.morning || category == AzkarCategory.evening,
      );
  final AzkarCategory category;
  @override
  Map<String, Object> toJson() => {
    'v': 1,
    'type': 'azkar_collection',
    'category': category.name,
  };
  @override
  List<Object?> get props => [category];
}
