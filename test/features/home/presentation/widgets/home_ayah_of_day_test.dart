import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/home/domain/entities/ayah_of_day.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_ayah_of_day.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';

class _MockAudioPlayerCubit extends Mock implements QuranAudioPlayerCubit {}

void main() {
  late _MockAudioPlayerCubit audioCubit;

  setUp(() {
    audioCubit = _MockAudioPlayerCubit();
    when(() => audioCubit.state).thenReturn(const QuranAudioPlayerState());
    when(() => audioCubit.stream).thenAnswer(
      (_) => const Stream.empty(),
    );
  });

  AyahOfDay ayah({
    String? surahType,
    int? surahAyahCount,
  }) {
    return AyahOfDay(
      surahId: 2,
      ayahNumber: 255,
      text: 'ٱللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
      surahNameAr: 'البقرة',
      surahNameEn: 'Al-Baqarah',
      pageNumber: 42,
      surahType: surahType,
      surahAyahCount: surahAyahCount,
    );
  }

  Widget harness(AyahOfDay ayahEntity) {
    return BlocProvider<QuranAudioPlayerCubit>.value(
      value: audioCubit,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeAyahOfDayCard(
              ayah: ayahEntity,
              skin: HomeSkin.forBrightness(Brightness.light),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the factual surah context line when available',
      (tester) async {
    await tester.pumpWidget(
      harness(ayah(surahType: 'medinan', surahAyahCount: 286)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medinan · 286 ayahs'), findsOneWidget);
  });

  testWidgets('shows the meccan label for meccan surahs', (tester) async {
    await tester.pumpWidget(
      harness(ayah(surahType: 'meccan', surahAyahCount: 7)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meccan · 7 ayahs'), findsOneWidget);
  });

  testWidgets('omits the context line on legacy entities without metadata',
      (tester) async {
    await tester.pumpWidget(harness(ayah()));
    await tester.pumpAndSettle();

    expect(find.textContaining('ayahs'), findsNothing);
  });
}
