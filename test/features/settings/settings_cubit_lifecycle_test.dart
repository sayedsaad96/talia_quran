import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/services/app_version_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/settings/presentation/cubits/settings_cubit.dart';

class _MockMemorizationRepository extends Mock
    implements MemorizationPlusRepository {}

class _VersionProvider implements AppVersionInfoProvider {
  @override
  Future<AppVersionInfo> getVersionInfo() async =>
      const AppVersionInfo(version: '1', buildNumber: '1');
}

void main() {
  test('closing settings during profile load does not emit afterward', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = _MockMemorizationRepository();
    final pendingProfile = Completer<Either<Failure, MemorizationProfile>>();
    when(() => repository.getMemorizationProfile())
        .thenAnswer((_) => pendingProfile.future);
    final resolver = MemorizationPathResolver(repository);
    final cubit = SettingsCubit(repository, prefs, resolver, _VersionProvider());

    final loading = cubit.load();
    await cubit.close();
    pendingProfile.complete(left(const CacheFailure()));
    await loading;

    expect(cubit.isClosed, isTrue);
    await resolver.dispose();
  });
}
