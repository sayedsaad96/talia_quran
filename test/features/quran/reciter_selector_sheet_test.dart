import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/features/quran/presentation/widgets/reciter_selector_sheet.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<QuranReciterService>(QuranReciterService(prefs));
  });

  tearDown(() => getIt.reset());

  testWidgets('reciter options build without hidden ListTile material', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ReciterSelectorSheet())),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ListTile), findsWidgets);
  });
}
