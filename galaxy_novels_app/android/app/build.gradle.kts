import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val testAdMobApplicationId = "ca-app-pub-3940256099942544~3347511713"
val releaseBuildRequested =
    gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { input -> load(input) }
    }
}

fun propertyOrEnv(name: String): String? {
    return providers.gradleProperty(name)
        .orElse(providers.environmentVariable(name))
        .orNull
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
}

fun truthyPropertyOrEnv(name: String): Boolean {
    return propertyOrEnv(name)?.lowercase() in setOf("1", "true", "yes")
}

fun keystoreProperty(name: String): String? {
    return keystoreProperties.getProperty(name)?.trim()?.takeIf { it.isNotEmpty() }
}

val releaseSigningConfigured =
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .all { keystoreProperty(it) != null }

android {
    namespace = "com.galaxynovels.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.galaxynovels.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["adMobApplicationId"] = testAdMobApplicationId
    }

    signingConfigs {
        create("release") {
            if (releaseSigningConfigured) {
                storeFile = rootProject.file(keystoreProperty("storeFile")!!)
                storePassword = keystoreProperty("storePassword")
                keyAlias = keystoreProperty("keyAlias")
                keyPassword = keystoreProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["adMobApplicationId"] = testAdMobApplicationId
        }

        release {
            val releaseAdMobApplicationId = propertyOrEnv("ADMOB_ANDROID_APP_ID")
            val allowTestAdsInRelease = truthyPropertyOrEnv("ALLOW_TEST_ADS_IN_RELEASE")
            val allowDebugSigningInRelease =
                truthyPropertyOrEnv("ALLOW_DEBUG_SIGNING_IN_RELEASE")

            if (releaseBuildRequested &&
                releaseAdMobApplicationId == null &&
                !allowTestAdsInRelease
            ) {
                throw GradleException(
                    "Missing ADMOB_ANDROID_APP_ID for release. " +
                        "Pass -PADMOB_ANDROID_APP_ID=ca-app-pub-...~... or " +
                        "set ALLOW_TEST_ADS_IN_RELEASE=true only for local testing."
                )
            }

            if (releaseBuildRequested &&
                !releaseSigningConfigured &&
                !allowDebugSigningInRelease
            ) {
                throw GradleException(
                    "Missing Android release signing config. Create android/key.properties " +
                        "with storeFile, storePassword, keyAlias, and keyPassword, or set " +
                        "ALLOW_DEBUG_SIGNING_IN_RELEASE=true only for local testing."
                )
            }

            manifestPlaceholders["adMobApplicationId"] =
                releaseAdMobApplicationId ?: testAdMobApplicationId
            signingConfig =
                if (releaseSigningConfigured) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
