import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/features/quran/data/datasources/bookmark_service.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/presentation/widgets/ayah_options_sheet.dart';

class MockQuranAudioPlayerCubit extends Mock implements QuranAudioPlayerCubit {}

class MockBookmarkService extends Mock implements BookmarkService {}

void main() {
  late MockQuranAudioPlayerCubit mockAudioCubit;
  late MockBookmarkService mockBookmarkService;

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<QuranReciterService>(QuranReciterService(prefs));

    mockBookmarkService = MockBookmarkService();
    getIt.registerSingleton<BookmarkService>(mockBookmarkService);

    mockAudioCubit = MockQuranAudioPlayerCubit();
    when(() => mockAudioCubit.state).thenReturn(const QuranAudioPlayerState());
    when(() => mockAudioCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() => getIt.reset());

  Widget buildTestWidget() {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<QuranAudioPlayerCubit>.value(
          value: mockAudioCubit,
          child: AyahOptionsSheet(
            ayah: const Ayah(
              number: 285,
              surahId: 2,
              text:
                  'ءَامَنَ الرَّسُولُ بِمَا أُنزِلَ إِلَيْهِ مِن رَّبِّهِۦ وَالْمُؤْمِنُونَ',
              numberInSurah: 285,
            ),
            surahName: 'البقرة',
            onInteraction: () {},
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders single memorization button and no duplicate memorization action',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify exactly one "ابدأ الحفظ" button exists
      expect(find.text('ابدأ الحفظ'), findsOneWidget);
      expect(find.byIcon(TaliaIcons.school), findsOneWidget);

      // Verify duplicate / page memorization action is not present
      expect(find.byIcon(TaliaIcons.reading), findsNothing);
      expect(find.textContaining('حفظ هذه'), findsNothing);

      // Verify expected core actions are present
      expect(find.text('تشغيل'), findsOneWidget);
      expect(find.text('نسخ'), findsOneWidget);
      expect(find.text('إشارة مرجعية'), findsOneWidget);
      expect(find.text('مشاركة'), findsOneWidget);
    },
  );
}
