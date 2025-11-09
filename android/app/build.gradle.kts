plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.brightness"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        // Use Java 21 as the target JVM for Kotlin compilation. Ensure JDK 21
        // is installed and available to Gradle (via JAVA_HOME or org.gradle.java.home).
        jvmTarget = "21"
    }

    // Hint Gradle/Kotlin to use a Java 21 toolchain for Kotlin compilation when
    // available. This does not install Java for you — install JDK 21 and set
    // JAVA_HOME or configure Gradle's org.gradle.java.home to point to it.
    // The `jvmToolchain(21)` API is supported by the Kotlin Gradle plugin 1.8+
    // and higher versions (we have Kotlin 2.x in plugins), so this should work.
    kotlin {
        jvmToolchain(21)
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.brightness"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
