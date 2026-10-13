import '../entities/kids_family_practice_receipt.dart';

/// Guardian-confirmed family-practice receipts for the child on this device.
abstract interface class KidsFamilyPracticeRepository {
  List<KidsFamilyPracticeReceipt> receipts();

  /// Idempotent by receipt id. False when the save failed or the account
  /// changed meanwhile; nothing is written for another account.
  Future<bool> record(KidsFamilyPracticeReceipt receipt);
}
