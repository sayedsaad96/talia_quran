package com.example.talia_quran.prayer

/**
 * Sound-profile → bundled raw-resource mapping (muezzin selection).
 *
 * Profiles are sent from Dart inside the existing `soundProfile` field and
 * follow the same vocabulary as `MuezzinCatalog` in
 * `lib/core/services/prayer_sound.dart`. Every unknown/missing profile
 * MUST degrade to the bundled default clip (`res/raw/adhan.mp3`) — a bad
 * preference value can never break adhan delivery.
 *
 * The fajr seam stays explicit: `fajr:<profile>` overrides the general
 * muezzin for fajr only (e.g. the bundled Al-Afasy fajr recording).
 */
object AdhanClipResolver {
    const val PROFILE_DEFAULT = "default"
    const val PROFILE_MAKKAH = "makkah"
    const val PROFILE_ABDULBASIT = "abdulbasit"
    const val PROFILE_QATAMI = "qatami"
    const val PROFILE_SURAIHI = "suraihi"
    const val PROFILE_AFASY_FAJR = "afasy_fajr"

    /** Prefix marking a fajr-only override inside `soundProfile`. */
    const val FAJR_OVERRIDE_PREFIX = "fajr:"
    const val DEFAULT_CLIP = "adhan"

    /** Every profile shipped in res/raw (keep in sync with the Dart catalog). */
    val SUPPORTED_PROFILES = setOf(
        PROFILE_DEFAULT,
        PROFILE_MAKKAH,
        PROFILE_ABDULBASIT,
        PROFILE_QATAMI,
        PROFILE_SURAIHI,
        PROFILE_AFASY_FAJR,
    )

    /** Pure mapping — JVM-testable, no Android types. */
    fun rawResourceName(soundProfile: String?, prayerKey: String): String {
        val profile = soundProfile?.trim().orEmpty()
        if (profile.isEmpty() || profile == PROFILE_DEFAULT) return DEFAULT_CLIP
        if (profile.startsWith(FAJR_OVERRIDE_PREFIX)) {
            // "fajr:<x>" applies only to fajr; other prayers keep the default
            // clip, and an unknown fajr override degrades to the default clip
            // for fajr itself.
            if (prayerKey != "fajr") return DEFAULT_CLIP
            val override = profile.substring(FAJR_OVERRIDE_PREFIX.length).trim()
            return if (override.isEmpty() || override == PROFILE_DEFAULT) {
                DEFAULT_CLIP
            } else {
                clipFor(override) ?: DEFAULT_CLIP
            }
        }
        return clipFor(profile) ?: DEFAULT_CLIP // unknown profile → bundled clip
    }

    private fun clipFor(profile: String): String? {
        if (!SUPPORTED_PROFILES.contains(profile)) return null
        if (profile == PROFILE_DEFAULT) return DEFAULT_CLIP
        return "adhan_$profile"
    }
}