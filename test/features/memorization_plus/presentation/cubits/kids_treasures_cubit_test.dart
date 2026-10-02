import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_log.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_treasures_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _MockMemorizationRepo extends Mock
    implements MemorizationPlusRepository {}

class _MockQuranRepo extends Mock implements QuranRepository {}

Surah _surah(int id, int ayahCount) => Surah(
  id: id,
  nameAr: 's$id',
  nameEn: 's$id',
  ayahCount: ayahCount,
  juz: 30,
  type: 'meccan',
  page: 604,
);

KidsSessionLog _log(int surahId, int ayah) => KidsSessionLog(
  id: '$surahId-$ayah',
  surahId: surahId,
  ayahNumber: ayah,
  repeatsCompleted: 3,
  pointsEarned: 10,
  completedAt: DateTime(2026, 10, 1),
);

void main() {
  late _MockMemorizationRepo memRepo;
  late _MockQuranRepo quranRepo;

  setUp(() {
    memRepo = _MockMemorizationRepo();
    quranRepo = _MockQuranRepo();
  });

  KidsTreasuresCubit build(List<CertificateAward> certs) =>
      KidsTreasuresCubit(memRepo, quranRepo, certificatesLoader: () => certs);

  test('loads region progress and the kids certificates', () async {
    when(() => memRepo.getKidsSessionLogs()).thenAnswer(
      (_) async => Right([for (var a = 1; a <= 6; a++) _log(114, a)]),
    );
    when(
      () => quranRepo.getSurahs(),
    ).thenAnswer((_) async => Right([_surah(114, 6), _surah(113, 5)]));
    final cert = CertificateAward(
      id: 'c1',
      titleAr: 'شهادة',
      type: CertificateType.surah,
      earnedAt: DateTime(2026, 10, 1),
    );

    final cubit = build([cert]);
    addTearDown(cubit.close);
    await cubit.load();

    final state = cubit.state as KidsTreasuresLoaded;
    expect(state.regions[1].memorized, 1);
    expect(state.certificates.length, 1);
  });

  test('a surahs-load failure emits KidsTreasuresError', () async {
    when(
      () => memRepo.getKidsSessionLogs(),
    ).thenAnswer((_) async => const Right(<KidsSessionLog>[]));
    when(
      () => quranRepo.getSurahs(),
    ).thenAnswer((_) async => const Left(CacheFailure()));

    final cubit = build(const []);
    addTearDown(cubit.close);
    await cubit.load();

    expect(cubit.state, isA<KidsTreasuresError>());
    expect(
      (cubit.state as KidsTreasuresError).message,
      CubitMessageCodes.errorCache,
    );
  });

  test('a session-log failure emits KidsTreasuresError', () async {
    when(
      () => memRepo.getKidsSessionLogs(),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    when(
      () => quranRepo.getSurahs(),
    ).thenAnswer((_) async => Right([_surah(114, 6)]));

    final cubit = build(const []);
    addTearDown(cubit.close);
    await cubit.load();

    expect(cubit.state, isA<KidsTreasuresError>());
  });

  test('a throwing certificates loader emits KidsTreasuresError', () async {
    when(
      () => memRepo.getKidsSessionLogs(),
    ).thenAnswer((_) async => const Right(<KidsSessionLog>[]));
    when(
      () => quranRepo.getSurahs(),
    ).thenAnswer((_) async => Right([_surah(114, 6)]));

    final cubit = KidsTreasuresCubit(
      memRepo,
      quranRepo,
      certificatesLoader: () => throw StateError('boom'),
    );
    addTearDown(cubit.close);
    await cubit.load();

    expect(cubit.state, isA<KidsTreasuresError>());
  });
}
