import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/share_good_injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/domain/repositories/share_good_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registers one store and fails closed with rollout off', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final services = GetIt.asNewInstance();
    addTearDown(services.reset);
    services.registerSingleton(preferences);
    services.registerSingleton(ExperienceFlags.fromPreferences(preferences));

    registerShareGood(services);

    expect(
      services<ShareGoodLocalStore>(),
      same(services<ShareGoodLocalStore>()),
    );
    final repository = services<ShareGoodRepository>();
    expect(repository, same(services<ShareGoodRepository>()));
    expect(
      await repository.resolve('unavailable-invite'),
      const Left(ShareGoodFailure.featureUnavailable),
    );
  });
}
