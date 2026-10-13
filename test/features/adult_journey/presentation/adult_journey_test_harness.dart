import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/adult_journey/adult_journey_feature_flags.dart';
import 'package:talia_quran/features/adult_journey/application/adult_journey_usecases.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_context.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_update.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_cubit.dart';

class MockLoadAdultJourney extends Mock implements LoadAdultJourney {}

class MockUpdateAdultJourney extends Mock implements UpdateAdultJourney {}

/// Fixed "today" used by the widget tests (a local date: 2026-10-13).
final adultTestNow = DateTime(2026, 10, 13, 10);
const adultTestToday = '2026-10-13';

/// A real cubit over mocked use cases, with every flag on.
class AdultCubitFixture {
  AdultCubitFixture({
    AdultJourneyPreferences preferences = AdultJourneyPreferences.empty,
    this.ownerId = 'owner-a',
  }) {
    registerFallbackValue(const ClearAdultToday());
    when(
      () => load(any()),
    ).thenAnswer((_) async => AdultJourneyLoadResult.ready(preferences));
    cubit = AdultJourneyCubit(
      loadAdultJourney: load,
      updateAdultJourney: update,
      flags: AdultJourneyFlags((_) => true),
      owner: _Owner(ownerId),
      accountChanges: const Stream<void>.empty(),
      now: () => adultTestNow,
    );
  }

  final String ownerId;
  final load = MockLoadAdultJourney();
  final update = MockUpdateAdultJourney();
  late final AdultJourneyCubit cubit;

  AdultJourneyContext context({
    List<UnifiedJourneyAction> actions = const [],
    bool hasPlan = false,
  }) => AdultJourneyContext(
    ownerId: ownerId,
    isAdult: true,
    now: adultTestNow,
    actions: actions,
    hasActiveAdultPlan: hasPlan,
    hasAdultReviewRecords: false,
    hasDueAdultReview: false,
  );

  void updateReturns(AdultJourneySaveResult result) {
    when(() => update(any(), any())).thenAnswer((_) async => result);
  }
}

class _Owner implements RecordOwnerProvider {
  const _Owner(this.currentOwnerId);

  @override
  final String currentOwnerId;

  @override
  bool get isSignedIn => true;
}

Widget adultTestApp({
  required Widget home,
  String locale = 'en',
  double textScale = 1.0,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    locale: Locale(locale),
    theme: ThemeData(brightness: brightness),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(body: home),
  );
}

/// [adultTestApp] for a [GoRouter] (shell and root-navigator tests).
Widget adultTestRouterApp({required GoRouter router, String locale = 'en'}) {
  return MaterialApp.router(
    locale: Locale(locale),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}
