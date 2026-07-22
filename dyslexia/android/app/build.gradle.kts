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

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
