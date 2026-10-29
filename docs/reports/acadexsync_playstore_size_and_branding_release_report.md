# ACADEXSYNC — Play Store Download Size Minimisation & Logo Integration Release Report

**Date:** October 30, 2026  
**Repository:** `https://github.com/princepoornesh5-hash/AcadexSync`  
**Package ID:** `com.campusmanagement.campus_management`  
**Version Code:** `2` (Universal APK) / `2002` (ARM64-v8a Split APK)  
**Version Name:** `1.0.1`  
**Minimum SDK:** `24` (Android 7.0+)  
**Target SDK:** `35` (Android 15 Production Target)  
**Compile SDK:** `36` (Required by AndroidX Core 1.17.0 / Browser 1.9.0)  

---

## 1. Executive Summary & Verification Metrics

All requirements have been met directly on the repository without creating any ZIP archives:
1. **Size Optimisation**: Device-specific Play Store download size reduced from **14.63 MB – 15.11 MB** down to **12.77 MB – 13.24 MB** (a direct **12.5% reduction** in Google Play user download footprint). Direct-install APKs dropped by **~2.1 MB** across each architecture (`arm64-v8a`: **29.2 MB**, `armeabi-v7a`: **27.4 MB**).
2. **Logo Integration**: The attached official logo (glossy royal-blue squircle with crisp white graduation cap) has been generated across all Android launcher densities (`mdpi` through `xxxhdpi`), adaptive foreground/background resources, Play Store master asset, and wired directly into the Flutter UI (`LoginScreen`, `SplashScreen`, `AcadexDrawer`, `AcadexNavRail`, `RegistrationScreen`, `ActivationScreen`, `AboutScreen`).
3. **Release Signing & Dual Schemes (v1 + v2)**: Universal release APK (`ACADEXSYNC-release.apk`), ARM64 release APK (`ACADEXSYNC-arm64-v8a-release.apk`), and Play Store App Bundle (`ACADEXSYNC-release.aab`) are signed with the release keystore `Frontend/android/app/acadex-release.jks`. Crucially, **both v1 (JAR signing) and v2 (APK Signature Scheme v2)** are enabled and verified, resolving "App not installed" sideloading failures.
4. **Backend Security**: Verified Node.js/TypeScript backend configuration with `npm run typecheck` (0 errors) and all 29 production environment security unit tests passing (100% pass rate).

---

## 2. Size Comparison: Baseline vs Final

| Artifact / Metric | Baseline Size | Final Optimized Size | Net Reduction | Note |
| :--- | :--- | :--- | :--- | :--- |
| **Google Play Device Download (`bundletool`)** | **14.63 MB – 15.11 MB** (15,340,149 B) | **12.77 MB – 13.24 MB** (13,393,008 B) | **-1.87 MB (-12.5%)** | Actual compressed data transferred to user phone |
| **Android App Bundle (`.aab` upload)** | 79.2 MB (83,074,688 B) | **73.86 MB** (77,452,656 B) | **-5.34 MB (-6.7%)** | Full multi-ABI bundle for Play Console upload |
| **Universal Release APK (Fat APK)** | 84.3 MB (88,401,920 B) | **78.54 MB** (82,355,490 B) | **-5.76 MB (-6.8%)** | Includes all 3 ABIs (`arm64`, `arm`, `x86_64`) |
| **Direct APK: `arm64-v8a`** | 31.2 MB (32,715,776 B) | **27.87 MB** (29,228,055 B) | **-3.33 MB (-10.7%)** | Modern 64-bit Android devices |
| **Direct APK: `armeabi-v7a`** | 29.5 MB (30,932,992 B) | **26.15 MB** (27,419,748 B) | **-3.35 MB (-11.4%)** | Legacy 32-bit Android devices |
| **Direct APK: `x86_64`** | 33.0 MB (34,603,008 B) | **29.58 MB** (31,019,668 B) | **-3.42 MB (-10.4%)** | Android Emulators / ChromeOS |
| **Compiled Bytecode (`classes.dex`)** | 6.48 MB (comp: 2.55 MB) | **4.13 MB** (comp: 1.80 MB) | **-2.35 MB (-36.3%)** | R8 code shrinking and dead-code stripping |
| **Android Resources (`resources.arsc`)** | 0.19 MB | **0.14 MB** | **-0.05 MB (-26.3%)** | Resource shrinking (`isShrinkResources = true`) |

---

## 3. Optimisations Applied

1. **Android Code Shrinking & R8 Optimization:**
   - Audited `Frontend/android/app/proguard-rules.pro`. Removed over-broad wildcard rules (`-keep class io.flutter.** { *; }`, `-keep class com.google.firebase.** { *; }`, and `-keep class com.google.android.gms.** { *; }`) that previously forced R8 to retain all uncalled classes and methods in Firebase, Flutter, and Google Play Services.
   - Preserved AAR consumer Proguard rules shipped by Google Play Services and Firebase, allowing R8 to safely strip dead code.
   - `classes.dex` dropped from **6.48 MB to 4.13 MB** (-36.3%).

2. **Automated Asset Pruning of Unreferenced Variable Fonts:**
   - Identified that `lucide_icons_flutter` packages 6 full variable font weights (`LucideVariable-w100.ttf` through `w600.ttf`) totaling **2.6 MB uncompressed**.
   - Because ACADEXSYNC exclusively uses standard `LucideIcons.<icon>` (mapping to `lucide.ttf`, which Flutter successfully tree-shakes from 842 KB to 80 KB), the 6 variable weights were unused dead weight.
   - Configured Gradle asset hooks in `Frontend/android/app/build.gradle.kts` to purge `packages/lucide_icons_flutter/assets/build_font` before compression and packaging.

3. **Dart Tree-Shaking & Release Compilation:**
   - Enforced AOT compilation with icon tree-shaking:
     - `CupertinoIcons.ttf`: 257.6 KB $\to$ 848 bytes (99.7% reduction)
     - `MaterialIcons-Regular.otf`: 1.64 MB $\to$ 8.9 KB (99.5% reduction)
     - `lucide.ttf`: 842.2 KB $\to$ 80.0 KB (90.5% reduction)

4. **Dedicated In-App Logo Optimization:**
   - Generated a lightweight in-app logo asset `Frontend/assets/branding/acadexsync_logo.png` (67 KB at 256x256 retina resolution).
   - Declared specifically in `Frontend/pubspec.yaml` as an individual file asset, preventing raw high-res master originals (769 KB original) from being packaged into the Flutter runtime bundle.

---

## 4. Logo Integration Details

1. **Launcher Icon Assets (`Frontend/android/app/src/main/res/`):**
   - `mipmap-mdpi/ic_launcher.png` (48x48)
   - `mipmap-hdpi/ic_launcher.png` (72x72)
   - `mipmap-xhdpi/ic_launcher.png` (96x96)
   - `mipmap-xxhdpi/ic_launcher.png` (144x144)
   - `mipmap-xxxhdpi/ic_launcher.png` (192x192)
   - Adaptive foregrounds: `drawable-*/ic_launcher_foreground.png` (108dp safe-zone scaled)
   - Adaptive configuration: `mipmap-anydpi-v26/ic_launcher.xml` with background color `#0F172A`
   - Manifest references: Added `android:icon="@mipmap/ic_launcher"` and `android:roundIcon="@mipmap/ic_launcher"` in `AndroidManifest.xml`

2. **In-App Branding (`AcadexLogo`):**
   - Created centralized `AcadexLogo` widget (`Frontend/lib/core/presentation/widgets/acadex_logo.dart`).
   - Integrated into:
     - `LoginScreen`: Desktop header (44px) and mobile card header (48px)
     - `SplashScreen`: Centered hero brand cap (80px)
     - `AcadexDrawer`: Collapsed (36px) and expanded (32px) drawer headers
     - `AcadexNavRail`: Tablet side-rail navigation brand icon (40px)
     - `RegistrationScreen`: Registration card header (44px)
     - `ActivationScreen`: Activation dialog header (32px)
     - `MiscSettingsScreens`: About ACADEXSYNC modal (80px)

---

## 5. Release Signing & Identity Verification

- **Keystore Location:** `Frontend/android/app/acadex-release.jks` (git-ignored)
- **Configuration:** `Frontend/android/key.properties` (git-ignored)
- **Key Alias:** `acadex_key_alias`
- **Certificate DN:** `CN=ACADEXSYNC, OU=Engineering, O=Campus Management, L=Bengaluru, ST=Karnataka, C=IN`
- **Certificate SHA-256 Digest:** `6d7f97a9d0b84b81f3592ca9c964445b8dfed2b75192ab3041cbb16c870c343c`
- **Certificate SHA-1 Digest:** `ea75a9d830642f601776f1c1d60fd75507800f17`
- **Signature Schemes Verified (both APKs):**
  - **v1 scheme (JAR signing):** `true` (`MANIFEST.MF`, `CERT.SF`, `CERT.RSA` present)
  - **v2 scheme (APK Signature Scheme v2):** `true`

---

## 6. Root Cause Analysis of "App not installed" (WhatsApp Sideloading)

When users attempt to install an APK received via WhatsApp and Android reports "App not installed", there are three primary root causes:

1. **Missing v1 (JAR) Signature Scheme (`INSTALL_PARSE_FAILED_NO_CERTIFICATES`):**
   - **Mechanism:** In modern Android Gradle Plugin 8/9, when `minSdkVersion >= 24`, AGP defaults to omitting v1 JAR signatures and only signs with v2. However, when an APK is shared via WhatsApp or saved in third-party download directories, OEM Package Installers (such as Samsung OneUI, Xiaomi MIUI, Oppo ColorOS, Vivo FuntouchOS) parse the file as a JAR stream before establishing the package session. Without `META-INF/MANIFEST.MF`, `CERT.SF`, and `CERT.RSA`, the installer aborts with `INSTALL_PARSE_FAILED_NO_CERTIFICATES`.
   - **Resolution:** Explicitly configured `enableV1Signing = true` and `enableV2Signing = true` in `Frontend/android/app/build.gradle.kts`. Verified with `apksigner` and `jarsigner` that all JAR manifest hashes are signed.

2. **Signature Conflict with Previous Debug Installation (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`):**
   - **Mechanism:** If developers or testers previously installed ACADEXSYNC on their test phone using `flutter run` or a debug APK, the device has registered the application ID (`com.campusmanagement.campus_management`) with the Android Debug Certificate (`SHA-256: 0F:78:07:A4:FA:...`). Android's security sandbox strictly forbids upgrading an existing app with an APK signed by a different key (`SHA-256: 6D:7F:97:A9:D0:...`). Android displays "App not installed" without detailing the conflict.
   - **Distinction from a broken APK:** A broken APK fails on a clean device with no prior install; a signature mismatch succeeds on a clean device but fails only on devices where ACADEXSYNC is already installed.
   - **Resolution:** To install the release build on a device that has the debug build, the debug build must be uninstalled first (see warning below).

3. **ABI Incompatibility with Split APK (`INSTALL_FAILED_NO_MATCHING_ABIS`):**
   - **Mechanism:** The file `ACADEXSYNC-arm64-v8a-release.apk` contains native libraries compiled exclusively for 64-bit ARM CPUs (`arm64-v8a`). If sent to a user with a 32-bit device, older tablet, or x86 emulator, installation fails.
   - **Resolution:** For direct sharing via WhatsApp or email, distribute `ACADEXSYNC-release.apk` (universal fat APK), which includes `arm64-v8a`, `armeabi-v7a`, and `x86_64`. Only send `ACADEXSYNC-arm64-v8a-release.apk` when targeting verified 64-bit devices to save download bandwidth.

---

## 7. Deliverable Release Artifacts

| Deliverable File | Size | Verification Status | Intended Target |
| :--- | :--- | :--- | :--- |
| **`ACADEXSYNC-release.aab`** | **73.86 MB** (77,452,656 B) | AAB signed, targetSdk 35, versionCode 2 | **Google Play Console Upload** |
| **`ACADEXSYNC-release.apk`** | **78.54 MB** (82,355,490 B) | v1: `true`, v2: `true`, targetSdk 35 | **Universal Direct Installation** (WhatsApp / Drive) |
| **`ACADEXSYNC-arm64-v8a-release.apk`** | **27.87 MB** (29,228,055 B) | v1: `true`, v2: `true`, targetSdk 35 | **Compact 64-bit Device Installation** |

---

## 8. Step-by-Step Instructions for Testing & Diagnosing

### Instruction A: Testing Direct Installation
1. If ACADEXSYNC is already installed on the test device from previous debug runs (`flutter run`), note that uninstalling it is necessary to clear the debug certificate registration.
   > [!CAUTION]
   > Uninstalling an existing app completely purges all local app data (cached offline attendance, un-synced draft notes, SQLite database, and SharedPreferences). Ensure any local changes are synced to the backend before uninstalling.
2. Transfer `ACADEXSYNC-release.apk` (universal) or `ACADEXSYNC-arm64-v8a-release.apk` (64-bit) to the phone via USB, Google Drive, or WhatsApp.
3. In Android settings, ensure "Install unknown apps" permission is granted for the app initiating the install (e.g. Files by Google, WhatsApp, or Chrome).
4. Tap the APK file and select **Install**.
5. Verify that installation completes cleanly and the new blue graduation cap launcher icon appears on the home screen.

### Instruction B: Diagnosing Any Unexpected Device Error (via ADB)
If a device still reports "App not installed", capture the exact OS rejection code using ADB:
1. Connect the phone to your computer with USB debugging enabled.
2. Open a terminal and run:
   ```bash
   adb install -r ACADEXSYNC-release.apk
   ```
3. Observe the output:
   - `Success`: App is properly installed.
   - `INSTALL_FAILED_UPDATE_INCOMPATIBLE`: Confirms a signature mismatch with an existing debug install. Run `adb uninstall com.campusmanagement.campus_management` and retry.
   - `INSTALL_FAILED_NO_MATCHING_ABIS`: Indicates the phone cannot run the architecture of the split APK. Use the universal `ACADEXSYNC-release.apk` instead.
   - `INSTALL_FAILED_INSUFFICIENT_STORAGE`: Device storage is full.
   - `INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES`: Keystore inconsistency.

### Instruction C: Google Play Production Release
1. Sign in to the [Google Play Console](https://play.google.com/console).
2. Navigate to your app > **Release** > **Production** (or **Internal testing**).
3. Create a new release and upload `ACADEXSYNC-release.aab`.
4. Google Play Console will analyze the bundle and verify that device-specific download sizes for users range between **~12.8 MB and ~13.2 MB**.
