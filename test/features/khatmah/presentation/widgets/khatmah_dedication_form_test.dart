import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_dedication_form.dart';

void main() {
  Widget buildWidget({
    KhatmahDedication? initialDedication,
    required ValueChanged<KhatmahDedication> onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: KhatmahDedicationForm(
            initialDedication: initialDedication,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  testWidgets('starts disabled by default and expands on toggle', (tester) async {
    KhatmahDedication? latestDedication;
    await tester.pumpWidget(
      buildWidget(
        onChanged: (d) => latestDedication = d,
      ),
    );
    await tester.pumpAndSettle();

    // Fields should not be visible when toggle is off
    expect(find.byKey(const Key('khatmah_dedication_recipient_name')), findsNothing);

    // Toggle on
    final toggle = find.byKey(const Key('khatmah_dedication_toggle'));
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    // Fields should now appear
    expect(find.byKey(const Key('khatmah_dedication_recipient_name')), findsOneWidget);
    expect(latestDedication, isNotNull);
    expect(latestDedication!.isDedicated, isTrue);

    // Toggle off
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('khatmah_dedication_recipient_name')), findsNothing);
    expect(latestDedication!.isDedicated, isFalse);
  });

  testWidgets('filling recipient name invokes onChanged with updated name', (tester) async {
    KhatmahDedication? latestDedication;
    await tester.pumpWidget(
      buildWidget(
        initialDedication: const KhatmahDedication(isDedicated: true),
        onChanged: (d) => latestDedication = d,
      ),
    );
    await tester.pumpAndSettle();

    final nameField = find.byKey(const Key('khatmah_dedication_recipient_name'));
    expect(nameField, findsOneWidget);

    await tester.enterText(nameField, 'والدتي الغالية');
    await tester.pumpAndSettle();

    expect(latestDedication?.recipientName, 'والدتي الغالية');
  });

  testWidgets('selecting condition choice chips updates condition', (tester) async {
    KhatmahDedication? latestDedication;
    await tester.pumpWidget(
      buildWidget(
        initialDedication: const KhatmahDedication(isDedicated: true),
        onChanged: (d) => latestDedication = d,
      ),
    );
    await tester.pumpAndSettle();

    // Tap deceased condition chip
    final deceasedChip = find.byKey(const Key('khatmah_dedication_condition_deceased'));
    expect(deceasedChip, findsOneWidget);
    await tester.tap(deceasedChip);
    await tester.pumpAndSettle();

    expect(latestDedication?.condition, DedicationCondition.deceased);

    // Tap sick condition chip
    final sickChip = find.byKey(const Key('khatmah_dedication_condition_sick'));
    expect(sickChip, findsOneWidget);
    await tester.tap(sickChip);
    await tester.pumpAndSettle();

    expect(latestDedication?.condition, DedicationCondition.sick);

    // Tap alive condition chip
    final aliveChip = find.byKey(const Key('khatmah_dedication_condition_alive'));
    expect(aliveChip, findsOneWidget);
    await tester.tap(aliveChip);
    await tester.pumpAndSettle();

    expect(latestDedication?.condition, DedicationCondition.alive);
  });

  testWidgets('selecting relationship dropdown updates relationship', (tester) async {
    KhatmahDedication? latestDedication;
    await tester.pumpWidget(
      buildWidget(
        initialDedication: const KhatmahDedication(isDedicated: true),
        onChanged: (d) => latestDedication = d,
      ),
    );
    await tester.pumpAndSettle();

    final dropdown = find.byKey(const Key('khatmah_dedication_relationship'));
    expect(dropdown, findsOneWidget);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    // Select 'صديق' from dropdown
    final item = find.text('صديق').last;
    await tester.tap(item);
    await tester.pumpAndSettle();

    expect(latestDedication?.relationship, 'صديق');
  });

  testWidgets('entering custom note updates customNote in dedication', (tester) async {
    KhatmahDedication? latestDedication;
    await tester.pumpWidget(
      buildWidget(
        initialDedication: const KhatmahDedication(isDedicated: true),
        onChanged: (d) => latestDedication = d,
      ),
    );
    await tester.pumpAndSettle();

    final noteField = find.byKey(const Key('khatmah_dedication_custom_note'));
    expect(noteField, findsOneWidget);

    await tester.enterText(noteField, 'اللهم اغفر له وارحمه');
    await tester.pumpAndSettle();

    expect(latestDedication?.customNote, 'اللهم اغفر له وارحمه');
  });
}
