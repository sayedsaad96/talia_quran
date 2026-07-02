abstract class JourneyDiagnostics {
  void record({
    required String legacyIntent,
    required String engineIntent,
    required String legacyRoute,
    required String engineRoute,
    required bool agreementResult,
  });
}

class NoOpJourneyDiagnostics implements JourneyDiagnostics {
  const NoOpJourneyDiagnostics();

  @override
  void record({
    required String legacyIntent,
    required String engineIntent,
    required String legacyRoute,
    required String engineRoute,
    required bool agreementResult,
  }) {
    // Intentionally empty for shadow mode
  }
}
