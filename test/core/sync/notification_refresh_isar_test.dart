import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/storage/app_isar.dart';
import 'package:talia_quran/core/sync/notification_refresh_worker.dart'
    show openNotificationRefreshIsar;
import 'package:talia_quran/features/streak/data/models/streak_isar.dart';
import '../../helpers/isar_test_core.dart';


Future<void> _initializeIsarCoreForTests() => initializeIsarCoreForTests();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'headless open preserves collections already stored in the app database',
    () async {
      await _initializeIsarCoreForTests();
      final directory = await Directory.systemTemp.createTemp(
        'talia_notification_refresh_',
      );
      final name =
          'notification_refresh_${DateTime.now().microsecondsSinceEpoch}';

      var isar = await openAppIsar(directory: directory.path, name: name);
      await isar.writeTxn(() async {
        await isar.streakIsars.put(
          StreakIsar()
            ..currentStreak = 17
            ..longestStreak = 21
            ..cloudDirty = true,
        );
      });
      await isar.close();

      isar = await openNotificationRefreshIsar(
        directory: directory.path,
        name: name,
      );
      expect((await isar.streakIsars.get(1))?.currentStreak, 17);
      await isar.close();

      isar = await openAppIsar(directory: directory.path, name: name);
      expect((await isar.streakIsars.get(1))?.longestStreak, 21);

      await isar.close(deleteFromDisk: true);
      if (await directory.exists()) await directory.delete(recursive: true);
    },
  );
}
