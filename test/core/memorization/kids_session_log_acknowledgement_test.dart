import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/kids_session_log_acknowledgement.dart';

void main() {
  test('acknowledges only the exact local IDs returned by the server', () {
    expect(
      KidsSessionLogAcknowledgement.acceptedIds(
        sentIds: const {'local-a', 'local-b'},
        acknowledgedRows: const [
          {'local_id': 'local-a'},
          {'local_id': 'another-device-log'},
        ],
      ),
      {'local-a'},
    );
  });
}
