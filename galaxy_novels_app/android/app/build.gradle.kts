import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val testAdMobApplicationId = "ca-app-pub-3940256099942544~3347511713"
val productionAdMobApplicationId = "ca-app-pub-4720168413129669~3354807098"
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

val hasProductionSigningConfig =
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .all { keystoreProperty(it) != null }
val allowDebugSigningInRelease =
    truthyPropertyOrEnv("ALLOW_DEBUG_SIGNING_IN_RELEASE")

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
            if (hasProductionSigningConfig) {
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

            manifestPlaceholders["adMobApplicationId"] =
                releaseAdMobApplicationId ?: productionAdMobApplicationId
            signingConfig = when {
                hasProductionSigningConfig -> signingConfigs.getByName("release")
                allowDebugSigningInRelease -> signingConfigs.getByName("debug")
                else -> null
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseArtifactRequested = allTasks.any { task ->
        task.project == project &&
            task.name.contains("Release", ignoreCase = true) &&
            listOf("assemble", "bundle", "package", "install")
                .any { prefix -> task.name.startsWith(prefix) }
    }
    if (
        releaseArtifactRequested &&
        !hasProductionSigningConfig &&
        !allowDebugSigningInRelease
    ) {
        throw GradleException(
            "Missing Android release signing config. Configure the " +
                "production keystore or set " +
                "ALLOW_DEBUG_SIGNING_IN_RELEASE=true for local testing only."
        )
    }
}

flutter {
    source = "../.."
}
