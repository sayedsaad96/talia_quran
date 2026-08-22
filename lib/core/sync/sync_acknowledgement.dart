/// Compares the immutable snapshot submitted to the backend with the record
/// currently stored on-device. A successful response must never acknowledge a
/// mutation that was made while the request was in flight.
class SyncAcknowledgement {
  const SyncAcknowledgement._();

  static bool matches({
    required Map<String, Object?> outbound,
    required Map<String, Object?> current,
  }) {
    if (outbound.length != current.length) return false;
    for (final entry in outbound.entries) {
      if (!_sameValue(current[entry.key], entry.value)) return false;
    }
    return true;
  }

  static bool _sameValue(Object? left, Object? right) {
    if (left is Iterable && right is Iterable) {
      final leftValues = left.toList(growable: false);
      final rightValues = right.toList(growable: false);
      if (leftValues.length != rightValues.length) return false;
      for (var index = 0; index < leftValues.length; index++) {
        if (!_sameValue(leftValues[index], rightValues[index])) return false;
      }
      return true;
    }
    return left == right;
  }
}
