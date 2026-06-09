import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/hifz/data/models/ayah_progress_model.dart';
import 'package:talia_quran/features/hifz/presentation/cubits/hifz_session_cubit.dart';
import 'package:talia_quran/features/hifz/presentation/pages/hifz_session_page.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('shows localized microphone permission feedback with retry', (
    tester,
  ) async {
    final cubit = _FakeHifzSessionCubit(
      _loadedState(HifzSpeechIssue.permissionDenied),
    );
    getIt.registerFactory<HifzSessionCubit>(() => cubit);

    await tester.pumpWidget(
      const _LocalizedApp(child: HifzSessionPage(surahId: 1, startAyah: 1)),
    );

    expect(
      find.text(
        'The app needs microphone permission for voice recitation. Please allow it from device settings.',
      ),
      findsOneWidget,
    );
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Open Settings'), findsNothing);

    await tester.tap(find.text('Try Again'));
    await tester.pump();

    expect(cubit.startRecordingCalls, 1);
  });

  testWidgets('shows speech unavailable feedback with settings action', (
    tester,
  ) async {
    final cubit = _FakeHifzSessionCubit(
      _loadedState(HifzSpeechIssue.unavailable),
    );
    getIt.registerFactory<HifzSessionCubit>(() => cubit);

    await tester.pumpWidget(
      const _LocalizedApp(child: HifzSessionPage(surahId: 1, startAyah: 1)),
    );

    expect(
      find.text('Voice recitation is unavailable on this device right now.'),
      findsOneWidget,
    );
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
  });
}

HifzSessionLoaded _loadedState(HifzSpeechIssue issue) {
  const surah = Surah(
    id: 1,
    nameAr: 'الفاتحة',
    nameEn: 'Al-Fatihah',
    ayahCount: 1,
    juz: 1,
    type: 'meccan',
    page: 1,
  );
  const ayah = Ayah(
    number: 1,
    surahId: 1,
    text: 'بسم الله الرحمن الرحيم',
    numberInSurah: 1,
  );

  return HifzSessionLoaded(
    surah: surah,
    ayahs: const [ayah],
    progressMap: {1: AyahProgressModel.initial(1, 1)},
    currentIndex: 0,
    speechIssue: issue,
  );
}

class _FakeHifzSessionCubit extends Cubit<HifzSessionState>
    implements HifzSessionCubit {
  _FakeHifzSessionCubit(super.initialState);

  int startRecordingCalls = 0;

  @override
  Future<void> startSession(int surahId, int startAyah) async {}

  @override
  Future<void> startRecording() async {
    startRecordingCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}
