import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatm_dua_datasource.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_khatm_dua_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatm_dua_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatm_dua_page.dart';

class MockGetKhatmDuaUsecase extends Mock implements GetKhatmDuaUsecase {}

void main() {
  late MockGetKhatmDuaUsecase mockGetKhatmDua;

  final sampleDuaData = KhatmDuaData(
    arabicText: 'اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ، وَاجْعَلْهُ لِي إِمَاماً وَنُوراً',
    source: 'مصحف مجمع الملك فهد لطباعة المصحف الشريف',
    sourceNote: 'دعاء مأثور ومشهور مطبوع في ملحق المصحف الشريف',
    tier: 'guidance',
    dedicationInserts: const {
      'alive': 'اللَّهُمَّ اجْعَلْ ثَوَابَ هَذِهِ التِّلَاوَةِ لِعَبْدِكَ {name}',
      'deceased': 'اللَّهُمَّ اغْفِرْ لِعَبْدِكَ {name} وَارْحَمْهُ',
      'sick': 'اللَّهُمَّ اشْفِ عَبْدَكَ {name}',
    },
  );

  setUp(() {
    mockGetKhatmDua = MockGetKhatmDuaUsecase();
  });

  Widget createWidget({
    required KhatmDuaCubit cubit,
    KhatmahDedication? dedication,
  }) {
    return MaterialApp(
      home: KhatmDuaPage(
        cubit: cubit,
        dedication: dedication,
      ),
    );
  }

  testWidgets('displays loading indicator while loading', (tester) async {
    when(() => mockGetKhatmDua()).thenAnswer(
      (_) => Future.delayed(const Duration(seconds: 1), () => sampleDuaData),
    );
    final cubit = KhatmDuaCubit(mockGetKhatmDua)..load();

    await tester.pumpWidget(createWidget(cubit: cubit));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('displays du\'a text, source attribution, and guidance tier badge when loaded', (tester) async {
    when(() => mockGetKhatmDua()).thenAnswer((_) async => sampleDuaData);
    final cubit = KhatmDuaCubit(mockGetKhatmDua);
    await cubit.load();

    await tester.pumpWidget(createWidget(cubit: cubit));
    await tester.pumpAndSettle();

    expect(find.textContaining('اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ'), findsOneWidget);
    expect(find.textContaining('مجمع الملك فهد'), findsOneWidget);
    expect(find.textContaining('إرشاد'), findsOneWidget);
  });

  testWidgets('increase and decrease font size buttons update font scale', (tester) async {
    when(() => mockGetKhatmDua()).thenAnswer((_) async => sampleDuaData);
    final cubit = KhatmDuaCubit(mockGetKhatmDua);
    await cubit.load();

    await tester.pumpWidget(createWidget(cubit: cubit));
    await tester.pumpAndSettle();

    final increaseBtn = find.byKey(const Key('khatm_dua_increase_font'));
    final decreaseBtn = find.byKey(const Key('khatm_dua_decrease_font'));

    expect(increaseBtn, findsOneWidget);
    expect(decreaseBtn, findsOneWidget);

    await tester.tap(increaseBtn);
    await tester.pumpAndSettle();
    expect((cubit.state as KhatmDuaLoaded).fontScale, 1.1);

    await tester.tap(decreaseBtn);
    await tester.pumpAndSettle();
    expect((cubit.state as KhatmDuaLoaded).fontScale, 1.0);
  });

  testWidgets('copy button copies text and displays snackbar', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        return null;
      }
      return null;
    });

    when(() => mockGetKhatmDua()).thenAnswer((_) async => sampleDuaData);
    final cubit = KhatmDuaCubit(mockGetKhatmDua);
    await cubit.load();

    await tester.pumpWidget(createWidget(cubit: cubit));
    await tester.pumpAndSettle();

    final copyBtn = find.byKey(const Key('khatm_dua_copy_button'));
    expect(copyBtn, findsOneWidget);

    await tester.tap(copyBtn);
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('renders dedication supplication when dedication is provided', (tester) async {
    when(() => mockGetKhatmDua()).thenAnswer((_) async => sampleDuaData);
    final cubit = KhatmDuaCubit(mockGetKhatmDua);
    await cubit.load();

    const dedication = KhatmahDedication(
      isDedicated: true,
      recipientName: 'الوالد رحمه الله',
      relationship: 'الأب',
      condition: DedicationCondition.deceased,
    );

    await tester.pumpWidget(createWidget(cubit: cubit, dedication: dedication));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('khatm_dua_dedication_card')), findsOneWidget);
    expect(find.textContaining('الوالد رحمه الله'), findsNWidgets(2));
    expect(find.textContaining('اللَّهُمَّ اغْفِرْ لِعَبْدِكَ الوالد رحمه الله'), findsOneWidget);
  });
}
