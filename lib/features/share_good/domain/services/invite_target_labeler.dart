import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/l10n/app_localizations_ar.dart';
import '../../../../core/l10n/app_localizations_en.dart';
import '../../../azkar/domain/entities/azkar_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../entities/invite_activity_target.dart';
import '../entities/invite_types.dart';

final class InviteTargetLabel extends Equatable {
  const InviteTargetLabel({
    required this.title,
    required this.startPage,
    required this.endPage,
  });
  final String title;
  final int startPage, endPage;
  @override
  List<Object?> get props => [title, startPage, endPage];
}

final class InviteTargetLabeler {
  const InviteTargetLabeler(this._repository);
  final QuranRepository _repository;
  Future<Either<ShareGoodFailure, InviteTargetLabel>> label(
    InviteActivityTarget target, {
    required bool arabic,
  }) async {
    final l10n = arabic ? AppLocalizationsAr() : AppLocalizationsEn();
    switch (target) {
      case QuranPageInviteTarget(:final pageNumber):
        return Right(
          InviteTargetLabel(
            title: '${l10n.page} $pageNumber',
            startPage: pageNumber,
            endPage: pageNumber,
          ),
        );
      case QuranWirdInviteTarget(:final startPage, :final endPage):
        return Right(
          InviteTargetLabel(
            title: '${l10n.pages} $startPage–$endPage',
            startPage: startPage,
            endPage: endPage,
          ),
        );
      case AzkarCollectionInviteTarget(:final category):
        return Right(
          InviteTargetLabel(
            title: category == AzkarCategory.morning
                ? l10n.morningAzkar
                : l10n.eveningAzkar,
            startPage: 0,
            endPage: 0,
          ),
        );
      case QuranSurahInviteTarget(:final surahId):
        final result = await _repository.getSurahDetail(surahId);
        return result.fold((_) => const Left(ShareGoodFailure.invalidInvite), (
          detail,
        ) {
          if (detail.surah.id != surahId || detail.ayahs.isEmpty) {
            return const Left(ShareGoodFailure.invalidInvite);
          }
          final start = detail.ayahs.first.page;
          final end = detail.ayahs.last.page;
          if (start == null ||
              end == null ||
              start < 1 ||
              end > 604 ||
              start > end) {
            return const Left(ShareGoodFailure.invalidInvite);
          }
          return Right(
            InviteTargetLabel(
              title: arabic ? detail.surah.nameAr : detail.surah.nameEn,
              startPage: start,
              endPage: end,
            ),
          );
        });
    }
  }
}
