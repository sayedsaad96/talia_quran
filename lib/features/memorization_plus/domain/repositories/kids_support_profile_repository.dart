import '../entities/kids_learning_support_profile.dart';

/// The guardian's learning-support answers for the child on this device.
abstract interface class KidsSupportProfileRepository {
  KidsLearningSupportProfile read();

  /// False when the save failed or the account changed meanwhile.
  Future<bool> save(KidsLearningSupportProfile profile);
}
