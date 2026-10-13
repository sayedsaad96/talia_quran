/// `YYYY-MM-DD` helpers for the adult journey's local-day fields.
abstract final class AdultLocalDate {
  static final _pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Formats the calendar day of [local] (already in the wanted zone).
  static String format(DateTime local) {
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// True for a real calendar date in `YYYY-MM-DD` form.
  static bool isValid(String value) {
    if (!_pattern.hasMatch(value)) return false;
    final parsed = DateTime.tryParse('${value}T00:00:00Z');
    return parsed != null && format(parsed) == value;
  }
}
