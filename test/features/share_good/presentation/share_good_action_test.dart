import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/config/supabase_config.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/presentation/widgets/share_good_action.dart';
import 'package:talia_quran/features/share_good/share_good_config.dart';

class FakeFlags extends Mock implements ExperienceFlags {}

class FakePath extends Mock implements MemorizationPathResolver {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeFlags flags;
  late FakePath path;
  setUp(() async {
    await getIt.reset();
    flags = FakeFlags();
    path = FakePath();
    when(() => flags.isEnabled(ExperienceFeature.shareGood)).thenReturn(true);
    when(() => path.changes).thenAnswer((_) => const Stream<void>.empty());
    getIt.registerSingleton<ShareGoodAvailability>(
      ShareGoodAvailability(
        flags,
        const SupabaseConfig(url: 'https://example.com', anonKey: 'key'),
        linkHost: 'example.com',
      ),
    );
    getIt.registerSingleton<MemorizationPathResolver>(path);
  });
  tearDown(() async => getIt.reset());
  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: ShareGoodAction(
            target: QuranPageInviteTarget(1),
            moment: InviteMoment.beforeActivity,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rollout off hides invitation action', (tester) async {
    when(() => flags.isEnabled(ExperienceFeature.shareGood)).thenReturn(false);
    await show(tester);
    expect(find.byType(FilledButton), findsNothing);
    verifyNever(() => path.currentProfile());
  });
  testWidgets('child and unknown profiles hide invitation action', (
    tester,
  ) async {
    when(() => path.currentProfile()).thenAnswer(
      (_) async => MemorizationProfile.empty().copyWith(
        selectedPath: MemorizationPath.child,
      ),
    );
    await show(tester);
    expect(find.byType(FilledButton), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    when(() => path.currentProfile()).thenAnswer((_) async => null);
    await show(tester);
    expect(find.byType(FilledButton), findsNothing);
  });
  testWidgets('eligible adult sees invitation action', (tester) async {
    when(() => path.currentProfile()).thenAnswer(
      (_) async => MemorizationProfile.empty().copyWith(
        selectedPath: MemorizationPath.adult,
      ),
    );
    await show(tester);
    expect(find.text('Create invitation'), findsOneWidget);
  });
  test('unsupported or malformed targets are rejected', () {
    for (final category in ['general', 'duas']) {
      expect(
        () => InviteActivityTarget.fromJson({
          'v': 1,
          'type': 'azkar_collection',
          'category': category,
        }),
        throwsFormatException,
      );
    }
    expect(
      () => InviteActivityTarget.fromJson({
        'v': 1,
        'type': 'quran_page',
        'page': 0,
      }),
      throwsFormatException,
    );
  });
}
