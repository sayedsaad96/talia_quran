// ignore_for_file: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/application/guardian_session_controller.dart';

void main() {
  final origin = DateTime.utc(2026, 10, 5, 9);

  void withSession(void Function(FakeAsync, GuardianSessionController) body) {
    fakeAsync((async) {
      final session = GuardianSessionController(
        clock: () => origin.add(async.elapsed),
      );
      body(async, session);
      session.dispose();
    });
  }

  test('starts inactive and opens with the return location', () {
    withSession((async, session) {
      expect(session.isActive, isFalse);

      session.start(returnLocation: '/memorization-plus/kids-home?surahId=1');

      expect(session.isActive, isTrue);
      expect(session.returnLocation, '/memorization-plus/kids-home?surahId=1');
    });
  });

  test('ends after ten idle minutes and tells listeners', () {
    withSession((async, session) {
      var ended = 0;
      session
        ..start(returnLocation: '/kids')
        ..addListener(() {
          if (!session.isActive) ended++;
        });

      async.elapse(const Duration(minutes: 9, seconds: 59));
      expect(session.isActive, isTrue);
      async.elapse(const Duration(seconds: 1));

      expect(session.isActive, isFalse);
      expect(ended, 1);
    });
  });

  test('guardian activity pushes the idle deadline back', () {
    withSession((async, session) {
      session.start(returnLocation: '/kids');

      async.elapse(const Duration(minutes: 8));
      session.touch();
      async.elapse(const Duration(minutes: 8));

      expect(session.isActive, isTrue);
      async.elapse(const Duration(minutes: 2));
      expect(session.isActive, isFalse);
    });
  });

  test('more than two minutes in the background ends it on resume', () {
    withSession((async, session) {
      session
        ..start(returnLocation: '/kids')
        ..appPaused();

      async.elapse(const Duration(minutes: 2, seconds: 1));
      session.appResumed();

      expect(session.isActive, isFalse);
    });
  });

  test('a short trip to the background keeps the session', () {
    withSession((async, session) {
      session
        ..start(returnLocation: '/kids')
        ..appPaused();

      async.elapse(const Duration(minutes: 1));
      session.appResumed();

      expect(session.isActive, isTrue);
      async.elapse(const Duration(minutes: 9));
      expect(session.isActive, isFalse);
    });
  });

  test('ending twice notifies once and touch does not revive it', () {
    withSession((async, session) {
      var notifications = 0;
      session
        ..start(returnLocation: '/kids')
        ..addListener(() => notifications++);

      session
        ..end()
        ..end()
        ..touch();

      expect(notifications, 1);
      expect(session.isActive, isFalse);
    });
  });
}
