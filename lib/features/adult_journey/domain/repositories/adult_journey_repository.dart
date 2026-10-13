import '../entities/adult_journey_preferences.dart';
import '../entities/adult_journey_update.dart';

/// Owner-scoped adult-journey preferences. Every call names the owner it was
/// started for; a different current owner yields an unavailable result
/// instead of data from, or a write to, another account.
abstract interface class AdultJourneyRepository {
  Future<AdultJourneyLoadResult> load({required String expectedOwnerId});

  Future<AdultJourneySaveResult> update({
    required String expectedOwnerId,
    required AdultJourneyUpdate command,
  });
}
