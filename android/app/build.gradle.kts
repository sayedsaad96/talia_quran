import java.util.Properties
import java.io.FileInputStream
import java.util.Base64
import java.util.Locale

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// The Dart-generated invite URL and Android's claimed host must be identical.
val shareGoodDartHosts = providers.gradleProperty("dart-defines").orNull
    ?.split(",")?.mapNotNull { encoded ->
        runCatching { String(Base64.getDecoder().decode(encoded), Charsets.UTF_8) }.getOrNull()
            ?.takeIf { it.startsWith("SHARE_GOOD_LINK_HOST=") }
            ?.substringAfter('=')
    } ?: emptyList()
require(shareGoodDartHosts.distinct().size <= 1) { "Conflicting SHARE_GOOD_LINK_HOST defines" }
val shareGoodDartHost = shareGoodDartHosts.firstOrNull().orEmpty()
val shareGoodGradleHost = providers.gradleProperty("shareGoodLinkHost").orNull.orEmpty()
val shareGoodHostPattern = Regex("""^(?=.{1,253}$)(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}$""")
val normalizedShareGoodHost = if (shareGoodDartHost.isEmpty()) {
    require(shareGoodGradleHost.isEmpty() || shareGoodGradleHost == "invalid.localhost") {
        "shareGoodLinkHost requires a matching SHARE_GOOD_LINK_HOST"
    }
    "invalid.localhost"
} else {
    require(shareGoodHostPattern.matches(shareGoodDartHost) &&
        shareGoodHostPattern.matches(shareGoodGradleHost) &&
        shareGoodDartHost.lowercase(Locale.ROOT) == shareGoodGradleHost.lowercase(Locale.ROOT) &&
        shareGoodDartHost.lowercase(Locale.ROOT) != "invalid.localhost") {
        "SHARE_GOOD_LINK_HOST and shareGoodLinkHost must be matching valid hosts"
    }
    shareGoodDartHost.lowercase(Locale.ROOT)
}

android {
    namespace = "com.talia.quran"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion
    useLibrary("android.test.runner", false)
    useLibrary("android.test.base", false)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.talia.quran"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "android.test.InstrumentationTestRunner"
        manifestPlaceholders["shareGoodLinkHost"] = normalizedShareGoodHost
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        getByName("debug") {
            // Keep runtime verification separate from an installed user's data.
            if (providers.gradleProperty("taliaRuntimeQa").orNull == "true") {
                applicationIdSuffix = ".runtimeqa"
                versionNameSuffix = "-runtimeqa"
            }
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.android.installreferrer:installreferrer:2.2")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Pure-JVM unit tests for the prayer delivery identity/codec (Prayer V2).
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20180813")
    implementation("com.google.android.material:material:1.14.0")
}
