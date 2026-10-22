import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_authority.dart';
import 'package:talia_quran/features/prayer_review/presentation/cubits/prayer_review_settings_cubit.dart';
import 'package:talia_quran/features/prayer_review/presentation/widgets/prayer_review_settings_slot.dart';

void main() {
  testWidgets('failed save leaves the controlled dropdown on persisted value', (
    tester,
  ) async {
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);
    final cubit = PrayerReviewSettingsCubit(
      isEnabled: () => true,
      captureAuthority: () => _authority(),
      readAdultEligibility: () async => true,
      readLength: (_, _) => 7,
      writeLength: (_, _, _, _) async => throw StateError('failed'),
      accountChanges: changes.stream,
    );
    addTearDown(cubit.close);
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: PrayerReviewSettingsPanel()),
        ),
      ),
    );
    await tester.pump();

    final dropdown = find.byKey(const Key('prayer_review_length_fajr'));
    expect(tester.widget<DropdownButton<int>>(dropdown).value, 7);
    await cubit.changeLength(PrayerKey.fajr, 15);
    await tester.pump();
    expect(tester.widget<DropdownButton<int>>(dropdown).value, 7);
  });
}

PrayerReviewAuthority _authority() => PrayerReviewAuthority(
  ownerId: 'owner-a',
  lease: _Lease(),
);

class _Lease implements AccountDataLease {
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  void check() {}

  @override
  void checkOwner(String ownerId) {}
}
