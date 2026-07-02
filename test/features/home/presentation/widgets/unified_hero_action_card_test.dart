import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/journey_presentation_data.dart';
import 'package:talia_quran/features/home/presentation/widgets/unified_hero_action_card.dart';
void main() {
  const tData = JourneyPresentationData(
    title: 'Test Title',
    subtitle: 'Test Subtitle',
    icon: Icons.star,
    route: '/test',
  );

  Widget createWidgetUnderTest({
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: UnifiedHeroActionCard(
          data: tData,
          isDark: isDark,
          onTap: onTap,
        ),
      ),
    );
  }

  testWidgets('renders title, subtitle and icon correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(isDark: false, onTap: () {}));
    
    // Allow animations to finish
    await tester.pumpAndSettle();

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Subtitle'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('triggers onTap callback when pressed', (WidgetTester tester) async {
    bool wasTapped = false;
    await tester.pumpWidget(createWidgetUnderTest(isDark: false, onTap: () {
      wasTapped = true;
    }));
    
    await tester.pumpAndSettle();

    await tester.tap(find.byType(UnifiedHeroActionCard));
    await tester.pumpAndSettle();

    expect(wasTapped, true);
  });
}
