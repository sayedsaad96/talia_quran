import '../domain/entities/adult_journey_preferences.dart';
import '../domain/entities/adult_journey_update.dart';
import '../domain/repositories/adult_journey_repository.dart';

class LoadAdultJourney {
  const LoadAdultJourney(this._repository);

  final AdultJourneyRepository _repository;

  Future<AdultJourneyLoadResult> call(String expectedOwnerId) =>
      _repository.load(expectedOwnerId: expectedOwnerId);
}

class UpdateAdultJourney {
  const UpdateAdultJourney(this._repository);

  final AdultJourneyRepository _repository;

  Future<AdultJourneySaveResult> call(
    String expectedOwnerId,
    AdultJourneyUpdate command,
  ) => _repository.update(expectedOwnerId: expectedOwnerId, command: command);
}
