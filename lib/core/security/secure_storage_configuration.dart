import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keep encrypted values and keys intact when Android storage cannot open.
const taliaSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    resetOnError: false,
    migrateOnAlgorithmChange: false,
  ),
);
