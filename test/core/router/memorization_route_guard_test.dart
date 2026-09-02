import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

/// Minimal repository fake that only answers [getMemorizationProfile]; every
/// other member is unused by the guards under test.
class _FakeMemoRepo implements MemorizationPlusRepository {
  _FakeMemoRepo(this._profile, {this.parentSettings = const ParentSettings()});

  final MemorizationProfile? _profile;
  final ParentSettings parentSettings;

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async {
    final profile = _profile;
    if (profile == null) return const Left(CacheFailure('no profile'));
    return Right(profile);
  }

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async => const Right([]);

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async =>
      const Right([]);

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, ParentSettings>> getParentSettings() async =>
      Right(parentSettings);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> hasPendingCloudWork() async => false;
}

class _FakeQuranRepo implements QuranRepository {
  _FakeQuranRepo({this.ayahCount = 7});

  final int ayahCount;

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async {
    return Right(
      SurahDetail(
        surah: Surah(
          id: surahId,
          nameAr: 'سورة',
          nameEn: 'Surah',
          ayahCount: ayahCount,
          juz: 1,
          type: 'meccan',
          page: 1,
        ),
        ayahs: List.generate(
          ayahCount,
          (i) => Ayah(
            number: i + 1,
            surahId: surahId,
            text: 'ayah',
            numberInSurah: i + 1,
            juz: 1,
            page: 1,
          ),
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lightweight [AuthCubit] stand-in that simply exposes a fixed state.
class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoRouterState extends Fake implements GoRouterState {
  _FakeGoRouterState(this._uri);

  final Uri _uri;

  @override
  Uri get uri => _uri;

  @override
  Object? get extra => null;
}

MemorizationProfile _profile(MemorizationPath path) => MemorizationProfile(
  schemaVersion: 1,
  selectedPath: path,
  guardianLinkStatus: GuardianLinkStatus.none,
  guardianOnboardingStatus: GuardianOnboardingStatus.completed,
  isParentGuardian: false,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

void main() {
  final getIt = GetIt.instance;

  void registerProfile(
    MemorizationProfile? profile, {
    ParentSettings parentSettings = const ParentSettings(),
  }) {
    if (getIt.isRegistered<MemorizationPlusRepository>()) {
      getIt.unregister<MemorizationPlusRepository>();
    }
    getIt.registerSingleton<MemorizationPlusRepository>(
      _FakeMemoRepo(profile, parentSettings: parentSettings),
    );
  }

  void registerAuth(AuthState state) {
    if (getIt.isRegistered<AuthCubit>()) {
      getIt.unregister<AuthCubit>();
    }
    getIt.registerSingleton<AuthCubit>(_FakeAuthCubit(state));
  }

  void registerQuran({int ayahCount = 7}) {
    if (getIt.isRegistered<QuranRepository>()) {
      getIt.unregister<QuranRepository>();
    }
    getIt.registerSingleton<QuranRepository>(
      _FakeQuranRepo(ayahCount: ayahCount),
    );
  }

  tearDown(() async {
    await getIt.reset();
  });

  group('adultOnlyRedirect', () {
    test('redirects child profiles to the kids home', () async {
      registerProfile(_profile(MemorizationPath.child));
      expect(
        await MemorizationRouteGuard.adultOnlyRedirect(),
        AppRoutes.memorizationPlusKidsHome,
      );
    });

    test('allows adult profiles', () async {
      registerProfile(_profile(MemorizationPath.adult));
      expect(await MemorizationRouteGuard.adultOnlyRedirect(), isNull);
    });

    test('allows guests with no profile', () async {
      registerProfile(null);
      expect(await MemorizationRouteGuard.adultOnlyRedirect(), isNull);
    });
  });

  group('kidsOnlyRedirect', () {
    test('redirects adult profiles to the memorization hub', () async {
      registerProfile(_profile(MemorizationPath.adult));
      expect(
        await MemorizationRouteGuard.kidsOnlyRedirect(),
        AppRoutes.memorizationPlus,
      );
    });

    test('allows child profiles', () async {
      registerProfile(_profile(MemorizationPath.child));
      expect(await MemorizationRouteGuard.kidsOnlyRedirect(), isNull);
    });

    test('allows guests with no profile', () async {
      registerProfile(null);
      expect(await MemorizationRouteGuard.kidsOnlyRedirect(), isNull);
    });
  });

  group('parentDashboardRedirect', () {
    test('redirects anonymous users to login', () async {
      registerProfile(_profile(MemorizationPath.adult));
      registerAuth(const AuthUnauthenticated());
      expect(
        await MemorizationRouteGuard.parentDashboardRedirect(),
        AppRoutes.login,
      );
    });

    test('redirects authenticated child profiles to the kids home', () async {
      registerProfile(_profile(MemorizationPath.child));
      registerAuth(const AuthInitial());
      expect(
        await MemorizationRouteGuard.parentDashboardRedirect(),
        AppRoutes.memorizationPlusKidsHome,
      );
    });

    test('allows authenticated adult profiles', () async {
      registerProfile(_profile(MemorizationPath.adult));
      registerAuth(const AuthInitial());
      expect(await MemorizationRouteGuard.parentDashboardRedirect(), isNull);
    });
  });

  group('hifzRedirect', () {
    test('redirects child profiles to the kids home', () async {
      registerProfile(_profile(MemorizationPath.child));
      final state = _FakeGoRouterState(Uri.parse(AppRoutes.hifz));
      expect(
        await MemorizationRouteGuard.hifzRedirect(state),
        AppRoutes.memorizationPlusKidsHome,
      );
    });

    test('redirects bare /hifz to memorization hub for adults', () async {
      registerProfile(_profile(MemorizationPath.adult));
      final state = _FakeGoRouterState(Uri.parse(AppRoutes.hifz));
      expect(
        await MemorizationRouteGuard.hifzRedirect(state),
        AppRoutes.memorizationHub,
      );
    });

    test('redirects /hifz?surahId to V2 via PendingAyahResolver', () async {
      registerProfile(_profile(MemorizationPath.adult));
      registerQuran(ayahCount: 7);
      final state = _FakeGoRouterState(
        Uri.parse('${AppRoutes.hifz}?surahId=1'),
      );
      final redirected = await MemorizationRouteGuard.hifzRedirect(state);
      expect(redirected, isNotNull);
      expect(redirected!, startsWith(AppRoutes.memorizationV2Session));
      expect(redirected, contains('surahId=1'));
      expect(redirected, contains('startAyah='));
    });

    test('redirects guests without legacy path to memorization-plus', () async {
      SharedPreferences.setMockInitialValues({});
      if (getIt.isRegistered<SharedPreferences>()) {
        getIt.unregister<SharedPreferences>();
      }
      getIt.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance(),
      );
      registerProfile(null);
      final state = _FakeGoRouterState(Uri.parse(AppRoutes.hifz));
      expect(
        await MemorizationRouteGuard.hifzRedirect(state),
        AppRoutes.memorizationPlus,
      );
    });
  });

  group('v2Session fallback', () {
    test('sends invalid V2 session parameters to the memorization hub', () {
      expect(
        MemorizationRouteGuard.invalidV2SessionRedirect(
          _FakeGoRouterState(
            Uri.parse('${AppRoutes.memorizationV2Session}?surahId=0'),
          ),
        ),
        AppRoutes.memorizationHub,
      );
    });
  });

  group('kidsJourneyRedirect', () {
    test('resolves a journey route without a surah', () async {
      registerProfile(_profile(MemorizationPath.child));
      final state = _FakeGoRouterState(
        Uri.parse(AppRoutes.memorizationPlusKidsJourney),
      );

      expect(
        await MemorizationRouteGuard.kidsJourneyRedirect(state),
        '${AppRoutes.memorizationPlusKidsJourney}?surahId=114',
      );
    });
  });

  group('kidsHomeRedirect', () {
    test('resolves a bare kids home route from the child settings', () async {
      registerProfile(
        _profile(MemorizationPath.child),
        parentSettings: const ParentSettings(startingSurahId: 112),
      );
      final state = _FakeGoRouterState(
        Uri.parse(AppRoutes.memorizationPlusKidsHome),
      );

      expect(
        await MemorizationRouteGuard.kidsHomeRedirect(state),
        '${AppRoutes.memorizationPlusKidsHome}?surahId=112',
      );
    });

    test('keeps an already resolved kids home route', () async {
      registerProfile(_profile(MemorizationPath.child));
      final state = _FakeGoRouterState(
        Uri.parse('${AppRoutes.memorizationPlusKidsHome}?surahId=113'),
      );

      expect(await MemorizationRouteGuard.kidsHomeRedirect(state), isNull);
    });
  });

  group('resolveKidsCompletionStarsEarned', () {
    test('defaults to 0 when extra and query are missing', () {
      expect(AppRouter.resolveKidsCompletionStarsEarned(), 0);
    });

    test('prefers extra over query parameters', () {
      expect(
        AppRouter.resolveKidsCompletionStarsEarned(
          extra: {'starsEarned': 3},
          queryParameters: {'starsEarned': '1'},
        ),
        3,
      );
    });
  });
}
