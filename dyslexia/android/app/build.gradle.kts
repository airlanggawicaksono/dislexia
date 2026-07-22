plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin handles Kotlin internally now.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.dyslexia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // Match the Java target above. Kotlin 2.2 otherwise defaults to the
        // JDK running Gradle (21), which trips AGP's Java/Kotlin JVM-target
        // consistency check.
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    lint {
        // Prevent lint from crashing the build with certain plugin versions
        // on AGP 8.x (e.g., camera_android_camerax lintVitalAnalyzeRelease).
        abortOnError = false
        checkReleaseBuilds = false
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.dyslexia"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val userHome = System.getProperty("user.home") ?: System.getenv("HOME") ?: "/root"
            val envKeystorePath = System.getenv("KEYSTORE_PATH")
            val envStorePassword = System.getenv("KEYSTORE_PASSWORD")
            val envKeyAlias = System.getenv("KEY_ALIAS")
            val envKeyPassword = System.getenv("KEY_PASSWORD")

            // Use env vars when set (CI), fall back to SDK debug keystore (local)
            // Check both null and empty string — GHA sets empty string for missing secrets.
            storeFile = file(
                if (!envKeystorePath.isNullOrEmpty()) envKeystorePath
                else "$userHome/.android/debug.keystore"
            )
            storePassword = if (!envStorePassword.isNullOrEmpty()) envStorePassword else "android"
            keyAlias = if (!envKeyAlias.isNullOrEmpty()) envKeyAlias else "androiddebugkey"
            keyPassword = if (!envKeyPassword.isNullOrEmpty()) envKeyPassword else "android"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

// Safety net: only run validateSigningRelease when the keystore file
// actually exists. In CI without secrets (or local dev without a release
// keystore), validation is skipped so the build doesn't fail.
tasks.matching {
    it.name.equals("validateSigningRelease")
}.configureEach {
    val envPath = System.getenv("KEYSTORE_PATH")
    val path = if (!envPath.isNullOrEmpty()) envPath
               else "${System.getProperty("user.home")}/.android/debug.keystore"
    enabled = file(path).exists()
}
