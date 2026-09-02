import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/create_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_setup_page.dart';

class MockCreateKhatmahUsecase extends Mock implements CreateKhatmahUsecase {}
class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  late MockCreateKhatmahUsecase mockCreateKhatmah;

  setUpAll(() {
    registerFallbackValue(FakeKhatmahPlan());
  });

  setUp(() {
    mockCreateKhatmah = MockCreateKhatmahUsecase();
  });

  Widget buildWidget({
    required KhatmahSetupCubit cubit,
    ValueChanged<String>? onNavigate,
  }) {
    final router = GoRouter(
      initialLocation: '/khatmah/setup',
      routes: [
        GoRoute(
          path: '/khatmah/setup',
          builder: (context, state) => KhatmahSetupPage(cubit: cubit),
        ),
        GoRoute(
          path: '/khatmah/dashboard',
          builder: (context, state) {
            onNavigate?.call('/khatmah/dashboard');
            return const Scaffold(
              body: Text('Khatmah Dashboard Page'),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  testWidgets('renders preset chips: 2, 4, 10, 20 and calculates live schedule', (tester) async {
    final cubit = KhatmahSetupCubit(mockCreateKhatmah);

    await tester.pumpWidget(buildWidget(cubit: cubit));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('khatmah_setup_preset_2')), findsOneWidget);
    expect(find.byKey(const Key('khatmah_setup_preset_4')), findsOneWidget);
    expect(find.byKey(const Key('khatmah_setup_preset_10')), findsOneWidget);
    expect(find.byKey(const Key('khatmah_setup_preset_20')), findsOneWidget);

    // Tap preset 2 (604 / 2 = 302 days)
    await tester.tap(find.byKey(const Key('khatmah_setup_preset_2')));
    await tester.pumpAndSettle();

    expect(find.textContaining('302'), findsOneWidget);

    // Tap preset 10 (604 / 10 = 61 days)
    await tester.tap(find.byKey(const Key('khatmah_setup_preset_10')));
    await tester.pumpAndSettle();

    expect(find.textContaining('61'), findsOneWidget);

    // Tap preset 20 (604 / 20 = 31 days)
    await tester.tap(find.byKey(const Key('khatmah_setup_preset_20')));
    await tester.pumpAndSettle();

    expect(find.textContaining('31'), findsOneWidget);
  });

  testWidgets('custom pages input updates calculation live', (tester) async {
    final cubit = KhatmahSetupCubit(mockCreateKhatmah);

    await tester.pumpWidget(buildWidget(cubit: cubit));
    await tester.pumpAndSettle();

    final customInput = find.byKey(const Key('khatmah_setup_custom_input'));
    expect(customInput, findsOneWidget);

    // Enter 5 pages/day -> 604 / 5 = 121 days
    await tester.enterText(customInput, '5');
    await tester.pumpAndSettle();

    expect(find.textContaining('121'), findsOneWidget);
  });

  testWidgets('toggling dedication expands dedication form and includes it in submission', (tester) async {
    when(() => mockCreateKhatmah(any())).thenAnswer((_) async {});
    final cubit = KhatmahSetupCubit(mockCreateKhatmah);

    await tester.pumpWidget(buildWidget(cubit: cubit));
    await tester.pumpAndSettle();

    // Toggle dedication
    final toggle = find.byKey(const Key('khatmah_dedication_toggle'));
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    // Enter recipient name
    final nameField = find.byKey(const Key('khatmah_dedication_recipient_name'));
    await tester.enterText(nameField, 'والدي الحبيب');
    await tester.pumpAndSettle();

    // Tap submit button
    final submitBtn = find.byKey(const Key('khatmah_setup_submit_button'));
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    verify(() => mockCreateKhatmah(any(
      that: isA<KhatmahPlan>().having(
        (p) => p.dedication.recipientName,
        'dedication.recipientName',
        'والدي الحبيب',
      ),
    ))).called(1);
  });

  testWidgets('successful plan creation navigates to /khatmah/dashboard', (tester) async {
    String? navigatedRoute;
    when(() => mockCreateKhatmah(any())).thenAnswer((_) async {});
    final cubit = KhatmahSetupCubit(mockCreateKhatmah);

    await tester.pumpWidget(buildWidget(
      cubit: cubit,
      onNavigate: (route) => navigatedRoute = route,
    ));
    await tester.pumpAndSettle();

    final submitBtn = find.byKey(const Key('khatmah_setup_submit_button'));
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(navigatedRoute, '/khatmah/dashboard');
    expect(find.text('Khatmah Dashboard Page'), findsOneWidget);
  });
}
