enum ProtectionDomain { progress, review, bookmarks, checkpoint }

enum ProtectionState { localOnly, unknown, pending, synced, failed }

class ProtectionDomainStatus {
  const ProtectionDomainStatus(
    this.state, {
    this.pendingCount,
    this.lastSuccess,
  }) : assert(pendingCount == null || pendingCount >= 0);
  final ProtectionState state;
  final int? pendingCount;
  final DateTime? lastSuccess;
}

class DataProtectionStatus {
  DataProtectionStatus({
    required this.signedIn,
    required Map<ProtectionDomain, ProtectionDomainStatus> domains,
  }) : domains = Map.unmodifiable(domains);
  final bool signedIn;
  final Map<ProtectionDomain, ProtectionDomainStatus> domains;
  ProtectionDomainStatus forDomain(ProtectionDomain domain) => !signedIn
      ? const ProtectionDomainStatus(ProtectionState.localOnly)
      : domains[domain] ??
            const ProtectionDomainStatus(ProtectionState.unknown);
}
