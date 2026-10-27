import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// -----------------------------------------------------------------------------
// Production Release Signing Configuration
// -----------------------------------------------------------------------------
// Loads signing credentials securely from an untracked `key.properties` file
// in the `android/` directory or from CI environment variables.
// Release builds will NOT silently fall back to debug signing.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystoreFile = keystorePropertiesFile.exists()

if (hasKeystoreFile) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

// Optional CI / Environment Variable fallback:
val ciStoreFile = System.getenv("KEYSTORE_PATH")
val ciStorePassword = System.getenv("KEYSTORE_PASSWORD")
val ciKeyAlias = System.getenv("KEY_ALIAS")
val ciKeyPassword = System.getenv("KEY_PASSWORD")
val hasCiSigning = !ciStoreFile.isNullOrEmpty() && !ciStorePassword.isNullOrEmpty() && !ciKeyAlias.isNullOrEmpty() && !ciKeyPassword.isNullOrEmpty()

val hasProductionSigning = hasKeystoreFile || hasCiSigning

android {
    namespace = "com.campusmanagement.campus_management"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.campusmanagement.campus_management"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasKeystoreFile) {
            create("release") {
                val storePath = keystoreProperties.getProperty("storeFile")
                storeFile = if (storePath != null) rootProject.file(storePath) else null
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        } else if (hasCiSigning) {
            create("release") {
                storeFile = file(ciStoreFile!!)
                storePassword = ciStorePassword
                keyAlias = ciKeyAlias
                keyPassword = ciKeyPassword
            }
        }
    }

    buildTypes {
        release {
            if (hasProductionSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // SECURITY GUARD:
                // When production release signing credentials are not present, signingConfig is set to null.
                // This guarantees the release build will NOT silently produce a debug-signed production artifact.
                signingConfig = null
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Debug builds explicitly use the default Android debug keystore
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
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

