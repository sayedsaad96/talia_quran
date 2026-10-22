import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/similar_ayah/similar_ayah_attempt_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/confusion_pair.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/similar_ayah_trainer_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/similar_ayah_trainer_page.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'shows exact comparison semantics, citations, and changed spans',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final cubit = (await tester.runAsync(() => _cubit()))!;
      await cubit.load();
      await cubit.choose(_pair);
      await tester.pumpWidget(_app(cubit));

      expect(find.bySemanticsLabel(RegExp('target body')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('other body')), findsOneWidget);
      expect(
        find.text('Target passage · Surah Al-Baqarah, Ayah 2'),
        findsOneWidget,
      );
      expect(
        find.text('Similar passage · Surah Aal-E-Imran, Ayah 1'),
        findsOneWidget,
      );
      expect(find.text('target body', findRichText: true), findsOneWidget);
      expect(find.text('other body', findRichText: true), findsOneWidget);
      final colored = tester
          .widgetList<RichText>(find.byType(RichText))
          .where((rich) => rich.text.toPlainText() == 'target body')
          .expand((rich) => _spans(rich.text));
      expect(colored.any((span) => span.style?.color != null), isTrue);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(cubit.close);
    },
  );

  testWidgets('pair list shows surah names and ayah numbers, not raw keys', (
    tester,
  ) async {
    final cubit = (await tester.runAsync(() => _cubit()))!;
    await cubit.load();
    await tester.pumpWidget(_app(cubit));
    expect(
      find.text(
        'Surah Al-Baqarah, Ayah 2  ↔  Surah Aal-E-Imran, Ayah 1',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('2:2'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(cubit.close);
  });

  testWidgets('practice hides then reveals the original without writes', (
    tester,
  ) async {
    var reads = 0;
    final cubit = (await tester.runAsync(
      () => _cubit(
        onRead: () async {
          reads++;
          return [_pair];
        },
      ),
    ))!;
    await cubit.load();
    await cubit.choose(_pair);
    await tester.pumpWidget(_app(cubit));
    final practice = find.text(
      'Recall the target passage, then reveal it when ready.',
    );
    await tester.scrollUntilVisible(practice, 200);
    await tester.tap(practice);
    await tester.pump();
    expect(find.text('target body', findRichText: true), findsNothing);
    expect(reads, 1);
    await tester.tap(find.text('Show target passage'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('target body', findRichText: true),
      -200,
    );
    expect(find.text('target body', findRichText: true), findsOneWidget);
    expect(reads, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(cubit.close);
  });

  testWidgets('failed comparison offers retry and can return to the list', (
    tester,
  ) async {
    final quran = _Repo()..failNext = true;
    final cubit = (await tester.runAsync(() => _cubit(quran: quran)))!;
    await cubit.load();
    await cubit.choose(_pair);
    await tester.pumpWidget(_app(cubit));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(cubit.state.failed, isFalse);
    expect(cubit.state.target!.ayah.text, 'target body');
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    expect(cubit.state.selected, isNull);
    expect(cubit.state.target, isNull);
    expect(find.byType(ListTile), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Arabic narrow large text remains scrollable without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = (await tester.runAsync(() => _cubit()))!;
    await cubit.load();
    await cubit.choose(_pair);
    await tester.pumpWidget(
      _app(cubit, locale: const Locale('ar'), width: 320, scale: 1.7),
    );

    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable), const Offset(0, -300));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(cubit.close);
  });
}

Future<SimilarAyahTrainerCubit> _cubit({
  Future<List<ConfusionPair>> Function()? onRead,
  QuranRepository? quran,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final barrier = AccountDataBarrier.forPreferences(prefs)
    ..owner = const FixedRecordOwnerProvider('adult-widget');
  final service = SimilarAyahAttemptService(
    owner: const FixedRecordOwnerProvider('adult-widget'),
    barrier: barrier,
    isEnabled: () => true,
    readAdultEligibility: () async => true,
    candidates: const UnavailableSimilarAyahCandidateSource(),
  );
  return SimilarAyahTrainerCubit(
    readPairs: onRead ?? () async => [_pair],
    quran: quran ?? _Repo(),
    captureAuthority: () =>
        service.captureAuthority() ??
        (throw const AccountDataUnavailableException()),
    accountChanges: service.accountChanges,
    readAdultEligibility: () async => true,
    isEnabled: () => true,
  );
}

Widget _app(
  SimilarAyahTrainerCubit cubit, {
  Locale locale = const Locale('en'),
  double width = 800,
  double scale = 1,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: Align(
      child: SizedBox(width: width, child: child),
    ),
  ),
  home: SimilarAyahTrainerPage(cubit: cubit),
);

final _pair = ConfusionPair(
  targetSurahId: 2,
  targetAyahNumber: 2,
  otherSurahId: 3,
  otherAyahNumber: 1,
  count: 2,
  firstAt: DateTime.utc(2026),
  lastAt: DateTime.utc(2026),
);

final class _Repo implements QuranRepository {
  bool failNext = false;
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int id) async {
    if (failNext) {
      failNext = false;
      return const Left(CacheFailure());
    }
    return Right(
      SurahDetail(
        surah: Surah(
          id: id,
          nameAr: 'x',
          nameEn: 'x',
          ayahCount: 3,
          juz: 1,
          type: 'x',
          page: 1,
        ),
        ayahs: [
          for (var n = 1; n <= 3; n++)
            Ayah(
              number: n,
              surahId: id,
              numberInSurah: n,
              text: id == 2 && n == 2
                  ? 'target body'
                  : id == 3 && n == 1
                  ? 'other body'
                  : 'previous $id',
            ),
        ],
      ),
    );
  }

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() async => const Right([]);
  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) async =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) async =>
      const Right([]);
  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) async =>
      const Right([]);
}

Iterable<TextSpan> _spans(InlineSpan span) sync* {
  if (span is TextSpan) {
    yield span;
    for (final child in span.children ?? const <InlineSpan>[]) {
      yield* _spans(child);
    }
  }
}
