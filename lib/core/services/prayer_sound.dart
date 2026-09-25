/// Sound selection for prayer-time notifications.
/// System sound or the bundled athan clip
/// (Android `res/raw/adhan.mp3`, iOS bundle `adhan.caf`).
enum PrayerSoundMode { system, athan }

/// One bundled adhan recording ("muezzin") the user can pick.
class Muezzin {
  const Muezzin({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.originAr,
    this.originEn,
    this.fajrOptimized = false,
  });

  /// Stable profile id. Travels inside `PrayerScheduledEvent.soundProfile`
  /// and MUST stay in sync with `AdhanClipResolver` (Kotlin) and the files
  /// under `res/raw/` / `ios/Runner/`.
  final String id;

  final String nameAr;
  final String nameEn;

  /// Where the recording comes from (mosque/city), for the picker subtitle.
  final String? originAr;
  final String? originEn;

  /// Marks the Fajr-specific recording in the picker.
  final bool fajrOptimized;

  String name(String localeName) => localeName.startsWith('ar') ? nameAr : nameEn;

  String? origin(String localeName) =>
      localeName.startsWith('ar') ? originAr : originEn;
}

/// The muezzins shipped with the app. `default` keeps the historical clip
/// so existing installs keep their current sound. Sources & licenses are
/// documented in `docs/audits/TALIA_PRAYER_MUEZZIN_SELECTION.md`.
class MuezzinCatalog {
  const MuezzinCatalog._();

  static const String defaultId = 'default';
  static const String fajrOverridePrefix = 'fajr:';

  static const List<Muezzin> all = [
    Muezzin(id: defaultId, nameAr: 'الأذان الافتراضي', nameEn: 'Default adhan'),
    Muezzin(
      id: 'makkah',
      nameAr: 'علي أحمد ملا',
      nameEn: 'Ali Ahmed Mulla',
      originAr: 'الحرم المكي',
      originEn: 'Grand Mosque, Makkah',
    ),
    Muezzin(
      id: 'abdulbasit',
      nameAr: 'عبد الباسط عبد الصمد',
      nameEn: 'Abdul Basit Abdul Samad',
      originAr: 'القاهرة',
      originEn: 'Cairo',
    ),
    Muezzin(
      id: 'qatami',
      nameAr: 'ناصر القطامي',
      nameEn: 'Nasser Al Qatami',
    ),
    Muezzin(
      id: 'suraihi',
      nameAr: 'عبدالمجيد السريحي',
      nameEn: 'Abdulmajid As-Suraihi',
      originAr: 'مسجد قباء',
      originEn: 'Quba Mosque',
    ),
    Muezzin(
      id: 'afasy_fajr',
      nameAr: 'مشاري العفاسي',
      nameEn: 'Mishary Al-Afasy',
      fajrOptimized: true,
    ),
  ];

  static Muezzin? byId(String id) {
    for (final muezzin in all) {
      if (muezzin.id == id) return muezzin;
    }
    return null;
  }

  static bool isSupported(String id) => byId(id) != null;
}

/// Resolves the `soundProfile` payload for one prayer occurrence:
///
/// - general muezzin → the profile id itself,
/// - a Fajr-only choice → `fajr:<id>` so native/Dart can apply it to fajr
///   occurrences only,
/// - an empty [fajrMuezzinId] or one equal to [muezzinId] means "same as
///   the other prayers".
String soundProfileForPrayer({
  required String prayerKey,
  required String muezzinId,
  required String fajrMuezzinId,
}) {
  final general = MuezzinCatalog.isSupported(muezzinId)
      ? muezzinId
      : MuezzinCatalog.defaultId;
  if (prayerKey != 'fajr') return general;
  final fajr = fajrMuezzinId.trim();
  if (fajr.isEmpty || fajr == general) return general;
  if (fajr == MuezzinCatalog.defaultId) return MuezzinCatalog.defaultId;
  if (!MuezzinCatalog.isSupported(fajr)) return general;
  return '${MuezzinCatalog.fajrOverridePrefix}$fajr';
}

class ResolvedPrayerSound {
  const ResolvedPrayerSound({
    required this.mode,
    required this.androidChannelId,
    required this.androidSoundName,
    required this.iOSSoundName,
  });

  final PrayerSoundMode mode;

  /// Android channels freeze their sound at creation, so the athan clip
  /// needs its own channel id; reusing the legacy id would keep the old
  /// sound on already-installed apps. The muezzin id is part of the channel
  /// id so switching muezzin gets a fresh channel with the new sound.
  final String androidChannelId;

  /// Raw-resource name without extension, null for the system default.
  final String? androidSoundName;

  /// Bundle file name with extension, null for the system default.
  final String? iOSSoundName;
}

ResolvedPrayerSound resolvePrayerSound({
  required bool athanEnabled,
  required String prayerKey,
  String soundProfile = MuezzinCatalog.defaultId,
}) {
  if (!athanEnabled) {
    return const ResolvedPrayerSound(
      mode: PrayerSoundMode.system,
      androidChannelId: 'talia_prayer_times',
      androidSoundName: null,
      iOSSoundName: null,
    );
  }
  final clip = _clipForProfile(soundProfile, prayerKey);
  final channelSuffix = _channelSuffixFor(soundProfile, prayerKey);
  return ResolvedPrayerSound(
    mode: PrayerSoundMode.athan,
    androidChannelId: channelSuffix.isEmpty
        ? 'talia_prayer_times_athan'
        : 'talia_prayer_times_athan_$channelSuffix',
    androidSoundName: clip,
    iOSSoundName: '$clip.caf',
  );
}

/// Channel suffix keeps a stable channel per effective clip so Android
/// never keeps a stale frozen sound. `default` keeps the historical id.
String _channelSuffixFor(String profile, String prayerKey) {
  final clip = _clipForProfile(profile, prayerKey);
  return clip == 'adhan' ? '' : clip.substring('adhan_'.length);
}

/// Mirrors `AdhanClipResolver` (Kotlin). Every unknown/missing profile
/// degrades to the bundled default clip — a bad preference value can never
/// break the adhan sound.
String _clipForProfile(String profile, String prayerKey) {
  final p = profile.trim();
  if (p.isEmpty || p == MuezzinCatalog.defaultId) return 'adhan';
  const fajrPrefix = MuezzinCatalog.fajrOverridePrefix;
  if (p.startsWith(fajrPrefix)) {
    if (prayerKey != 'fajr') return 'adhan';
    final override = p.substring(fajrPrefix.length).trim();
    if (override.isEmpty || override == MuezzinCatalog.defaultId) return 'adhan';
    return MuezzinCatalog.isSupported(override) ? 'adhan_$override' : 'adhan';
  }
  return MuezzinCatalog.isSupported(p) ? 'adhan_$p' : 'adhan';
}
