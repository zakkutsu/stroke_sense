plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.stroke_sense"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.stroke_sense"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
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

// Task untuk copy dan rename APK dengan nama custom
tasks.register("renameAPK") {
    doLast {
        val buildOutputs = file("$buildDir/outputs/flutter-apk")
        if (buildOutputs.exists()) {
            val debugApk = file("$buildOutputs/app-debug.apk")
            val releaseApk = file("$buildOutputs/app-release.apk")
            
            if (debugApk.exists()) {
                val newName = file("$buildOutputs/StrokeSense-debug.apk")
                debugApk.copyTo(newName, overwrite = true)
                println("✅ Debug APK renamed to: ${newName.name}")
            }
            
            if (releaseApk.exists()) {
                val newName = file("$buildOutputs/StrokeSense-release.apk")
                releaseApk.copyTo(newName, overwrite = true)
                println("✅ Release APK renamed to: ${newName.name}")
            }
        }
    }
}

// Auto-run rename after assembleDebug and assembleRelease
afterEvaluate {
    tasks.findByName("assembleDebug")?.finalizedBy("renameAPK")
    tasks.findByName("assembleRelease")?.finalizedBy("renameAPK")
}
