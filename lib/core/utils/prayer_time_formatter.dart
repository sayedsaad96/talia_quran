/// Utility for formatting remaining time until next prayer in Arabic and English.
///
/// Follows standard Arabic grammatical rules:
/// - Under 60 minutes: expressed in minutes (دقيقة / دقيقتين / دقائق / دقيقة).
/// - 60 minutes or more: expressed in hours (ساعة / ساعتين / ساعات / ساعة)
///   along with remaining minutes if any (و دقيقة / و دقيقتين / و X دقائق / و X دقيقة).
String formatPrayerRemainingTime(int minutes, {required bool isArabic}) {
  if (minutes <= 0) {
    return isArabic ? 'أقل من دقيقة' : 'less than a min';
  }

  if (minutes < 60) {
    return _formatMinutesOnly(minutes, isArabic: isArabic);
  }

  final hours = minutes ~/ 60;
  final remMinutes = minutes % 60;

  if (isArabic) {
    final hoursStr = _arabicHours(hours);
    if (remMinutes == 0) {
      return hoursStr;
    }
    final minsStr = _arabicMinutesConjunction(remMinutes);
    return '$hoursStr $minsStr';
  } else {
    if (remMinutes == 0) {
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    return '${hours}h ${remMinutes}m';
  }
}

/// Compact formatting for tight spaces like badges/chips (e.g. "6 س 34 د" or "25 د").
String formatPrayerRemainingTimeCompact(int minutes, {required bool isArabic}) {
  if (minutes <= 0) {
    return isArabic ? '< 1 د' : '< 1m';
  }

  if (minutes < 60) {
    return isArabic ? '$minutes د' : '$minutes min';
  }

  final hours = minutes ~/ 60;
  final remMinutes = minutes % 60;

  if (isArabic) {
    if (remMinutes == 0) {
      return '$hours س';
    }
    return '$hours س $remMinutes د';
  } else {
    if (remMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remMinutes}m';
  }
}

String _formatMinutesOnly(int minutes, {required bool isArabic}) {
  if (!isArabic) {
    return '$minutes min';
  }

  if (minutes == 1) {
    return 'دقيقة';
  } else if (minutes == 2) {
    return 'دقيقتين';
  } else if (minutes >= 3 && minutes <= 10) {
    return '$minutes دقائق';
  } else {
    return '$minutes دقيقة';
  }
}

String _arabicHours(int hours) {
  if (hours == 1) {
    return 'ساعة';
  } else if (hours == 2) {
    return 'ساعتين';
  } else if (hours >= 3 && hours <= 10) {
    return '$hours ساعات';
  } else {
    return '$hours ساعة';
  }
}

String _arabicMinutesConjunction(int minutes) {
  if (minutes == 1) {
    return 'ودقيقة';
  } else if (minutes == 2) {
    return 'ودقيقتين';
  } else if (minutes >= 3 && minutes <= 10) {
    return 'و $minutes دقائق';
  } else {
    return 'و $minutes دقيقة';
  }
}
