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

val hasValidKeystoreProps = hasKeystoreFile &&
    !keystoreProperties.getProperty("storeFile").isNullOrBlank() &&
    !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
    !keystoreProperties.getProperty("keyAlias").isNullOrBlank() &&
    !keystoreProperties.getProperty("keyPassword").isNullOrBlank() &&
    !keystoreProperties.getProperty("storePassword").contains("YOUR_KEYSTORE_PASSWORD")

// Optional CI / Environment Variable fallback:
val ciStoreFile = System.getenv("KEYSTORE_PATH")
val ciStorePassword = System.getenv("KEYSTORE_PASSWORD")
val ciKeyAlias = System.getenv("KEY_ALIAS")
val ciKeyPassword = System.getenv("KEY_PASSWORD")
val hasCiSigning = !ciStoreFile.isNullOrEmpty() && !ciStorePassword.isNullOrEmpty() && !ciKeyAlias.isNullOrEmpty() && !ciKeyPassword.isNullOrEmpty()

val hasProductionSigning = hasValidKeystoreProps || hasCiSigning

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
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasValidKeystoreProps) {
            create("release") {
                val storePath = keystoreProperties.getProperty("storeFile")
                storeFile = if (storePath != null) {
                    val rootResolved = rootProject.file(storePath)
                    if (rootResolved.exists()) rootResolved else file(storePath)
                } else null
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                enableV1Signing = true
                enableV2Signing = true
            }
        } else if (hasCiSigning) {
            create("release") {
                val rootResolved = rootProject.file(ciStoreFile!!)
                storeFile = if (rootResolved.exists()) rootResolved else file(ciStoreFile)
                storePassword = ciStorePassword
                keyAlias = ciKeyAlias
                keyPassword = ciKeyPassword
                enableV1Signing = true
                enableV2Signing = true
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
                // We also register a taskGraph check below to fail fast rather than silently producing an unsigned APK.
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

    gradle.taskGraph.whenReady {
        val requestedRelease = allTasks.any { task ->
            val name = task.name
            name.contains("Release", ignoreCase = true) && 
            (name.contains("assemble", ignoreCase = true) || 
             name.contains("package", ignoreCase = true) || 
             name.contains("bundle", ignoreCase = true))
        }
        if (requestedRelease && !hasProductionSigning) {
            throw GradleException(
                """
                |================================================================================
                |BUILD FAILED: Missing Android Release Signing Configuration
                |================================================================================
                |Android OS rejects unsigned APKs. A release APK must be signed with a valid
                |keystore before it can be installed on any physical Android device.
                |
                |To produce a signed release APK:
                |1. Generate a keystore if you haven't already:
                |   keytool -genkey -v -keystore acadex-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias acadex_key_alias
                |
                |2. Create 'Frontend/android/key.properties' (see 'key.properties.example'):
                |   storeFile=app/acadex-release.jks
                |   storePassword=<your-keystore-password>
                |   keyAlias=acadex_key_alias
                |   keyPassword=<your-key-password>
                |
                |Alternatively, inject CI environment variables:
                |   KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD
                |================================================================================
                """.trimMargin()
            )
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

// Optimization: Strip unused variable font assets from third-party icon packages
// that are not referenced in the application and that Flutter does not tree-shake automatically.
val pruneUnusedFonts = {
    listOf(
        file("${project.buildDir}/intermediates/flutter/release/flutter_assets/packages/lucide_icons_flutter/assets/build_font"),
        file("${project.buildDir}/intermediates/assets/release/mergeReleaseAssets/flutter_assets/packages/lucide_icons_flutter/assets/build_font")
    ).forEach { dir ->
        if (dir.exists()) {
            dir.deleteRecursively()
        }
    }
}

tasks.matching { it.name.startsWith("copyFlutterAssets") || it.name.startsWith("merge") && it.name.endsWith("Assets") }.configureEach {
    doLast { pruneUnusedFonts() }
}

tasks.matching { it.name.startsWith("compress") && it.name.endsWith("Assets") || it.name.startsWith("package") || it.name.startsWith("bundle") }.configureEach {
    doFirst { pruneUnusedFonts() }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

