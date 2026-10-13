import 'adult_journey_preferences.dart';

/// Typed commands applied to the latest stored record inside the account
/// barrier, so an older screen never overwrites a newer field.
sealed class AdultJourneyUpdate {
  const AdultJourneyUpdate();

  /// True for commands the user did not explicitly ask for. They never
  /// replace a corrupt record.
  bool get isAutomatic => false;
}

final class SaveAdultProfile extends AdultJourneyUpdate {
  const SaveAdultProfile({required this.goal, this.experience});

  final AdultJourneyGoal goal;
  final AdultJourneyExperience? experience;
}

final class SnoozeAdultSetup extends AdultJourneyUpdate {
  const SnoozeAdultSetup(this.localDate);

  final String localDate;
}

final class SetAdultToday extends AdultJourneyUpdate {
  SetAdultToday({
    required this.localDate,
    required this.minutes,
    this.lightReturn = false,
  }) {
    if (!adultJourneyMinuteChoices.contains(minutes)) {
      throw ArgumentError.value(minutes, 'minutes', 'must be 5, 10 or 20');
    }
  }

  final String localDate;
  final int minutes;
  final bool lightReturn;
}

/// «العودة للاقتراحات المعتادة»: clears today's choice only.
final class ClearAdultToday extends AdultJourneyUpdate {
  const ClearAdultToday();
}

/// An eligible adult Home visit. The repository decides the return offer
/// from the stored record; the caller never supplies the offer day.
final class RecordAdultHomeVisit extends AdultJourneyUpdate {
  const RecordAdultHomeVisit(this.nowUtc);

  final DateTime nowUtc;

  @override
  bool get isAutomatic => true;
}

final class DismissAdultReturn extends AdultJourneyUpdate {
  const DismissAdultReturn(this.localDate);

  final String localDate;
}

/// «بداية خفيفة اليوم»: five minutes, prefer existing review, and the return
/// invitation is done for today — one write. It pauses nothing and moves no
/// review dates.
final class StartAdultLightReturn extends AdultJourneyUpdate {
  const StartAdultLightReturn(this.localDate);

  final String localDate;
}

/// «أكمل كالمعتاد»: clears today's choice and the invitation for today; the
/// profile stays.
final class ContinueAdultAsUsual extends AdultJourneyUpdate {
  const ContinueAdultAsUsual(this.localDate);

  final String localDate;
}
