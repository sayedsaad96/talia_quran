import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/reading_checkpoint_injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/features/quran/data/repositories/reading_checkpoint_repository_impl.dart';
import 'reading_checkpoint_repository_test.dart' show SecureStore, Remote;

void main() {
  test(
    'rollout toggles gate transport without changing the local checkpoint authority',
    () async {
      final locator = GetIt.instance;
      await locator.reset();
      addTearDown(locator.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const owner = FixedRecordOwnerProvider('a');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      var enabled = true;
      locator.registerSingleton<ExperienceFlags>(
        ExperienceFlags((_) => enabled),
      );
      locator.registerSingleton<ReadingCheckpointRepositoryImpl>(
        ReadingCheckpointRepositoryImpl(
          prefs: prefs,
          owner: owner,
          barrier: barrier,
          secureStore: SecureStore(),
          remote: Remote(),
        ),
      );
      final session = AppSessionService(
        prefs,
        owner: owner,
        checkpointReader: readActiveReadingCheckpoint,
        checkpointWriter: writeActiveReadingCheckpoint,
      );
      await session.saveCurrentQuranCheckpoint(10);
      enabled = false;
      await session.saveCurrentQuranCheckpoint(30);
      enabled = true;
      expect(
        (await session.exportQuranCheckpoint(expectedOwnerId: 'a'))!.pageNumber,
        30,
      );
    },
  );
}
