import 'package:equatable/equatable.dart';

enum AzkarCategory { morning, evening, general, duas }

class Zikr extends Equatable {
  const Zikr({
    required this.id,
    required this.text,
    required this.transliteration,
    required this.translation,
    required this.totalCount,
    required this.category,
    this.reference = '',
    this.subcategory = '',
  });

  final String id;
  final String text;
  final String transliteration;
  final String translation;
  final int totalCount;
  final AzkarCategory category;
  final String reference;
  final String subcategory;

  @override
  List<Object?> get props => [id, text, totalCount, category, subcategory];
}

class ZikrSession extends Equatable {
  const ZikrSession({
    required this.zikr,
    required this.currentCount,
    required this.isDone,
  });

  final Zikr zikr;
  final int currentCount;
  final bool isDone;

  double get progress =>
      zikr.totalCount == 0 ? 0 : currentCount / zikr.totalCount;

  ZikrSession increment() {
    final next = currentCount + 1;
    return ZikrSession(
      zikr: zikr,
      currentCount: next.clamp(0, zikr.totalCount),
      isDone: next >= zikr.totalCount,
    );
  }

  ZikrSession reset() =>
      ZikrSession(zikr: zikr, currentCount: 0, isDone: false);

  @override
  List<Object?> get props => [zikr, currentCount, isDone];
}
