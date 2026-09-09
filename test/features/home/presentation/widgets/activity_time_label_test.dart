import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_activity_feed.dart';

void main() {
  late AppLocalizations l10n;
  final now = DateTime(2026, 9, 9, 15, 30);

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  test('just now is under a minute', () {
    expect(
      activityTimeLabel(l10n, now.subtract(const Duration(seconds: 20)), now),
      l10n.homeActivityJustNow,
    );
  });

  test('minutes ago under an hour', () {
    expect(
      activityTimeLabel(l10n, now.subtract(const Duration(minutes: 12)), now),
      l10n.homeActivityMinutesAgo(12),
    );
  });

  test('hours ago later the same day', () {
    expect(
      activityTimeLabel(l10n, now.subtract(const Duration(hours: 3)), now),
      l10n.homeActivityHoursAgo(3),
    );
  });

  test('yesterday is the previous local day', () {
    expect(
      activityTimeLabel(l10n, DateTime(2026, 9, 8, 21), now),
      l10n.homeActivityYesterday,
    );
  });

  test('older events use day counts', () {
    expect(
      activityTimeLabel(l10n, DateTime(2026, 9, 6, 10), now),
      l10n.homeActivityDaysAgo(3),
    );
  });
}
