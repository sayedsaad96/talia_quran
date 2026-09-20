import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/presentation/widgets/quran_audio_equalizer.dart';
import 'package:talia_quran/features/quran/presentation/widgets/quran_mini_player_bar.dart';

class MockQuranAudioPlayerCubit extends Mock implements QuranAudioPlayerCubit {}

void main() {
  late MockQuranAudioPlayerCubit mockCubit;

  setUp(() {
    mockCubit = MockQuranAudioPlayerCubit();
  });

  testWidgets('does not render when hasActiveAudio is false', (tester) async {
    when(() => mockCubit.state).thenReturn(const QuranAudioPlayerState());
    when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<QuranAudioPlayerCubit>.value(
            value: mockCubit,
            child: const QuranMiniPlayerBar(),
          ),
        ),
      ),
    );

    expect(find.byType(QuranAudioEqualizer), findsNothing);
    expect(find.text('الفاتحة'), findsNothing);
  });

  testWidgets('renders Mushaf badge, equalizer, surah name, reciter, and controls when active', (tester) async {
    const activeState = QuranAudioPlayerState(
      status: PlaybackStatus.playing,
      currentSurahId: 1,
      currentAyahNumber: 1,
      reciter: QuranReciter.alafasy,
      scope: PlayScope.surah,
      hasNext: true,
      hasPrevious: false,
      currentAyah: Ayah(
        number: 1,
        surahId: 1,
        text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        numberInSurah: 1,
      ),
    );

    when(() => mockCubit.state).thenReturn(activeState);
    when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: BlocProvider<QuranAudioPlayerCubit>.value(
            value: mockCubit,
            child: const QuranMiniPlayerBar(),
          ),
        ),
      ),
    );

    // Verify Mushaf badge icon is rendered
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);

    // Verify Surah Name
    expect(find.text('الفاتحة'), findsOneWidget);

    // Verify Ayah pill
    expect(find.text('آية 1'), findsOneWidget);

    // Verify Reciter name
    expect(find.text('مشاري راشد العفاسي'), findsOneWidget);

    // Verify Animated Equalizer is present
    expect(find.byType(QuranAudioEqualizer), findsOneWidget);

    // Verify Play/Pause button (pause icon since isPlaying)
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // Verify Close button
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}
