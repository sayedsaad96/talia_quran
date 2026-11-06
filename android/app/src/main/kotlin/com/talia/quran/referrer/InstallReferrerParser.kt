package com.talia.quran.referrer

/** Mirrors the strict invite referrer format for native contract checks. */
object InstallReferrerParser {
    private val pattern = Regex("inv=([A-Za-z0-9_-]{43})")

    fun parse(referrer: String): String? = pattern.matchEntire(referrer)?.groupValues?.get(1)
}
