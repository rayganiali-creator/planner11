plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.routineplanner.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true // flutter_local_notifications
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.routineplanner.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24   // همان minSdk نسخه‌ی Capacitor
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ===== امضای نسخه‌ی نهایی =====
    // همان کلید و همان متغیرهای محیطی (GitHub Secrets) نسخه‌ی Capacitor؛ بدون این،
    // بازار آپدیت را روی نسخه‌ی نصب‌شده نمی‌پذیرد. رمز و کلید هرگز داخل کد نیست.
    signingConfigs {
        create("release") {
            val ks = System.getenv("RP_STORE_FILE")
            if (ks != null) {
                storeFile = file(ks)
                storePassword = System.getenv("RP_STORE_PASSWORD")
                keyAlias = System.getenv("RP_KEY_ALIAS")
                keyPassword = System.getenv("RP_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (System.getenv("RP_STORE_FILE") != null)
                signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            // مثل نسخه‌ی Capacitor: بدون R8/shrink (Poolakey از reflection استفاده می‌کند؛ بدون قاعده‌ی proguard امن نیست)
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // پرداخت کافه‌بازار (همان نسخه‌ی Capacitor)
    implementation("com.github.cafebazaar.Poolakey:poolakey:2.2.0")
}

flutter {
    source = "../.."
}
