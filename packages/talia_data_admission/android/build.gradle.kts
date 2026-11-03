plugins { id("com.android.library") }
android {
    namespace = "com.talia.quran.admission"
    compileSdk = 37
    defaultConfig { minSdk = 21 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
