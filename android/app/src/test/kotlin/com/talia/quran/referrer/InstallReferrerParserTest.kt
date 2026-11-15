package com.talia.quran.referrer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class InstallReferrerParserTest {
    @Test fun parsesInviteToken() {
        val token = "a".repeat(41) + "_-"
        assertEquals(token, InstallReferrerParser.parse("inv=$token"))
    }

    @Test fun ignoresUtmReferrer() {
        assertNull(InstallReferrerParser.parse("utm_source=tc"))
    }

    @Test fun rejectsWrongLengthAndExtraParameters() {
        assertNull(InstallReferrerParser.parse("inv=${"a".repeat(42)}"))
        assertNull(InstallReferrerParser.parse("inv=${"a".repeat(43)}&utm_source=tc"))
    }
}
