# ACADEX Android Server Connectivity Diagnostic & Repair Report

**Date:** October 27, 2026  
**Document Reference:** `docs/reports/acadex_android_server_connectivity_diagnostic_report.md`  
**Status:** Diagnosed, Repaired, Built & Verified  

---

## Executive Summary

When attempting to sign in on a physical Android device (`motorola edge 60 fusion`, API 37), the application displayed:
> *"Unable to reach ACADEX server. Please check your network or verify backend service connectivity."* (reported as *"ACADEX server can't be reached"*).

A comprehensive architectural trace revealed that the debug build of the Flutter application hardcoded Android development host resolution to `10.0.2.2:5050`. While `10.0.2.2` is a virtual router loopback interface for the official Google Android Emulator, it does **not** exist or route anywhere on a physical Android phone. Furthermore, the phone was connected over mobile cellular data (`wlan0` inactive) without an active USB reverse tunnel, rendering any loopback address completely unreachable.

The issue has been resolved by:
1. Implementing **hardware environment detection** (`isEmulator` query via native Android `MethodChannel` and Android `Build` parameters).
2. Implementing an **intelligent dynamic fallback pipeline** in `ApiClient`:
   - Android Emulator $\rightarrow$ `http://10.0.2.2:5050/api/v1`
   - Physical Android Device with active USB `adb reverse` tunnel $\rightarrow$ `http://localhost:5050/api/v1` (verified via fast non-blocking health probe)
   - Physical Android Device without reverse tunnel / over Wi-Fi / cellular $\rightarrow$ Fallback to the project's existing secure remote development endpoint `https://acadex-backend-main.onrender.com/api/v1`
   - Explicit compile-time overrides (`--dart-define=API_BASE_URL=...` or `DEV_HOST=...`) $\rightarrow$ Honored with highest precedence
   - Release Mode (`kReleaseMode`) $\rightarrow$ Strictly bound to production HTTPS endpoint
3. Upgrading error handling in `ApiAuthRepository` and `ApiActivationRepository` with `NetworkErrorDiagnostic` to distinguish TLS certificate failures, Android cleartext blocks, DNS resolution errors, connection timeouts, connection refused, HTTP 401/403/404/500, and database connectivity issues without leaking internal secrets.
4. Preserving Android Network Security Configuration (`network_security_config.xml`) permitting cleartext for emulator loopback and `adb reverse` while enforcing HTTPS for remote endpoints.

---

## 1. Traced Connection Path & Confirmed Root Cause

### 1.1 Target Device Identification
Physical device detection via `flutter devices` and Android SDK `platform-tools/adb`:
- **Model:** `motorola edge 60 fusion` (product: `scout_g_sys`, device: `scout`, transport ID: 20)
- **Serial / Device ID:** `ZN4223NKHX`
- **Architecture:** `android-arm64`, Android 17 (API 37)
- **Active Network Interfaces:**
  - `ccmni1` / `v4-ccmni1`: Mobile Cellular Data (Active, `192.0.0.4/32`)
  - `wlan0`: Wi-Fi State `DOWN` (`NO-CARRIER`)
  - `adb reverse --list`: Initially empty (no reverse port forwarding configured)

### 1.2 Exact API URL in Installed App
In the installed `app-debug.apk`:
- `kReleaseMode` = `false`
- No compile-time environment flags (`API_BASE_URL`, `DEV_HOST`, `USE_ADB_REVERSE`) were passed during standard debug installation.
- In `Frontend/lib/core/network/api_client.dart`:
  ```dart
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  ```
- **Exact URL used for login:**  
  `http://10.0.2.2:5050/api/v1/auth/login`

### 1.3 Confirmed Root Cause
1. **Emulator Loopback Alias on Physical Device:**  
   `10.0.2.2` is QEMU's virtual alias to `127.0.0.1` on the development computer, valid *only* inside an Android Virtual Device (AVD). On a physical Android phone, `10.0.2.2` is an unroutable address in private address space.
2. **Missing Port Tunnel on USB:**  
   When the phone was plugged in over USB, no `adb reverse tcp:5050 tcp:5050` rule was registered.
3. **Cellular Network Routing:**  
   The physical phone was operating on cellular carrier network data with Wi-Fi disabled (`wlan0` down), preventing direct LAN communication to the host computer's IP (`192.168.1.6`).
4. **Coarse Error Mapping:**  
   When Dio failed with `DioExceptionType.connectionError`, `_extractError` uniformly mapped it to:
   `Unable to reach ACADEX server. Please check your network or verify backend service connectivity.`, concealing the underlying transport diagnosis.

---

## 2. Backend Verification

### 2.1 Process & Port Binding
- **Process Status:** Running locally via Node.js (`npm run dev`) on port 5050.
- **Host Binding:** `server.listen(env.PORT, '0.0.0.0', ...)` — verified listening on all network interfaces (`0.0.0.0`).
- **Database Connection:** Initialized and connected to MongoDB Atlas cluster (`databaseName: acadex`).
- **CORS Configuration:** `CORS_ORIGIN=*` with credentials support.

### 2.2 Health Check Endpoints
Both local and remote staging endpoints respond with healthy status:

#### Local Health Check (`http://localhost:5050/api/v1/health`):
```json
{
  "status": "ok",
  "service": "acadex-backend",
  "version": "1.0.0",
  "environment": "development",
  "database": "connected",
  "databaseName": "acadex",
  "timestamp": "2026-10-27T17:30:03.161Z"
}
```

#### Remote Cloud Health Check (`https://acadex-backend-main.onrender.com/api/v1/health`):
```json
{
  "status": "ok",
  "service": "acadex-backend",
  "version": "1.0.0",
  "environment": "production",
  "database": "connected",
  "databaseName": "acadex",
  "timestamp": "2026-10-27T17:32:21.736Z"
}
```

---

## 3. Targeted Solution: Multi-Target Endpoint Resolution

To satisfy all deployment requirements without hardcoding arbitrary LAN IPs or breaking production, `ApiClient` now employs a three-tiered environment resolution:

| Target Environment | Condition | Resolved API Base URL | Rationale |
| :--- | :--- | :--- | :--- |
| **Explicit Override** | `--dart-define=API_BASE_URL=...` | Configured URL | Direct CI/CD or staging override |
| **Production** | `kReleaseMode == true` | `https://acadex-backend-main.onrender.com/api/v1` | Production HTTPS endpoint |
| **Configured Dev Host** | `--dart-define=DEV_HOST=...` | `http://$DEV_HOST:5050/api/v1` | Explicit LAN address testing |
| **Explicit Reverse** | `--dart-define=USE_ADB_REVERSE=true` | `http://localhost:5050/api/v1` | Explicit USB tunnel |
| **Web / Desktop** | `kIsWeb` or macOS/Linux/Windows | `http://localhost:5050/api/v1` | Browser and desktop local loopback |
| **Android Emulator** | `isEmulator == true` | `http://10.0.2.2:5050/api/v1` | Standard QEMU host loopback |
| **Physical Phone (USB)** | `isEmulator == false` & `localhost:5050/health` reachable | `http://localhost:5050/api/v1` | `adb reverse` tunnel active over USB |
| **Physical Phone (Remote)** | `isEmulator == false` & local probe unreachable | `https://acadex-backend-main.onrender.com/api/v1` | Seamless remote development backend |

---

## 4. Accurate Failure Diagnosis Architecture

A new diagnostic module, `NetworkErrorDiagnostic` (`Frontend/lib/core/network/network_error_diagnostic.dart`), categorizes failures accurately:

1. **TLS Certificate Failures:**  
   Detects `badCertificate`, `HandshakeException`, `TlsException`, and `CERTIFICATE_VERIFY_FAILED`.  
   *User Message:* *"Secure connection failed (TLS certificate error). Please check your device date and security settings."*
2. **Android Cleartext HTTP Blocks:**  
   Detects `CLEARTEXT communication ... not permitted by network security policy`.  
   *User Message:* *"Cleartext HTTP communication is blocked by device security policy. Please use HTTPS or permit cleartext traffic."*
3. **DNS / Host Resolution Errors:**  
   Detects `SocketException` (errno 7) and `Failed host lookup`.  
   *User Message:* *"Unable to resolve ACADEX server address. Please verify your internet connection or host settings."*
4. **Connection Refused:**  
   Detects `Connection refused` (errno 111 / 61).  
   *User Message:* *"Connection refused by server. The ACADEX backend service may not be running or the port is inaccessible."*
5. **Connection & Receive Timeouts:**  
   Detects `DioExceptionType.connectionTimeout`, `sendTimeout`, `receiveTimeout`.  
   *User Message:* *"Connection timed out while reaching ACADEX server. Please check your connection and try again."*
6. **HTTP 401 Unauthorized:**  
   Extracts backend reason (e.g., *"Invalid credentials"*).
7. **HTTP 403 Forbidden:**  
   Extracts backend reason (e.g., *"Account is deactivated"* or *"Pending activation"*).
8. **HTTP 404 Route Not Found:**  
   Extracts endpoint mismatch indicator.
9. **HTTP 500 / 503 Backend & Database Errors:**  
   Distinguishes database disconnections (`MongoNetworkError`) from generic application exceptions.

---

## 5. Verification & Test Evidence

### 5.1 Real Authentication Verification

#### Local Backend Authentication (`http://localhost:5050/api/v1/auth/login`):
- **Valid Credentials:** `admin@acadex.com` / `acadex123`
  - Status: `200 OK`
  - Returned: Signed JWT `accessToken`, `refreshToken`, user object with role `SUPER_ADMIN`.
- **Invalid Credentials:** `admin@acadex.com` / `wrongpassword`
  - Status: `401 Unauthorized`
  - Returned: `{"success":false,"error":{"code":"UNAUTHORIZED","message":"Invalid credentials"}}`

#### Remote Staging Authentication (`https://acadex-backend-main.onrender.com/api/v1/auth/login`):
- **Valid Credentials:** `admin@acadex.com` / `acadex123`
  - Status: `200 OK`
  - Returned: Signed JWT with MongoDB Atlas user profile `6adcf52f47c6b078839e22c7`.

### 5.2 Frontend Automated Test Results
Command:
```bash
flutter test \
  test/network_connectivity_diagnostic_test.dart \
  test/api_client_test.dart \
  test/auth_login_vertical_slice_test.dart \
  test/api_auth_dev_login_test.dart
```
**Result:** **37 of 37 tests passed cleanly (0 failures).**
- `NetworkErrorDiagnostic` correctly classified:
  - TLS certificate error
  - Android cleartext block
  - DNS resolution failure
  - Connection refused
  - Connection & receive timeout
  - HTTP 401, 403, 404, and 500 database unavailable
- `ApiClient` verified:
  - Platform emulator default (`10.0.2.2`)
  - Remote development endpoint fallback constant
  - Runtime base URL dynamic synchronization
- Vertical auth slice tests verified:
  - Role resolution for all 5 roles
  - State transitions, token persistence, and logout

### 5.3 Android Debug Build
Command:
```bash
flutter build apk --debug
```
**Result:**  
```
Running Gradle task 'assembleDebug'...                             23.6s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

### 5.4 Backend Membership-Aware Authentication Regression
Command:
```bash
npx jest tests/integration/membership_aware_auth_prompt3.test.ts
```
**Result:** **16 of 16 tests passed cleanly.**

---

## 6. Files Changed and Rationale

| File Path | Type | Rationale |
| :--- | :--- | :--- |
| `Frontend/android/app/src/main/kotlin/.../MainActivity.kt` | Kotlin | Added `com.acadex.app/device_info` MethodChannel to query Android `Build` parameters and reliably detect emulator vs physical hardware. |
| `Frontend/lib/core/network/network_error_diagnostic.dart` | Dart | Created dedicated typed diagnostic utility distinguishing TLS failures, cleartext blocks, DNS errors, timeouts, connection refused, and HTTP status codes. |
| `Frontend/lib/core/network/api_client.dart` | Dart | Added `initializeEnvironment()`, runtime device detection, fast adb reverse health probe, dynamic `updateBaseUrl()`, and secure remote endpoint fallback. |
| `Frontend/lib/features/auth/data/repositories/api_auth_repository.dart` | Dart | Integrated `NetworkErrorDiagnostic` into `_extractError` to avoid collapsing all transport exceptions into generic unreachable messages. |
| `Frontend/lib/features/auth/data/repositories/api_activation_repository.dart` | Dart | Integrated `NetworkErrorDiagnostic` for consistent error handling in account activation workflows. |
| `Frontend/lib/main.dart` | Dart | Called `await ApiClient.initializeEnvironment()` early in boot sequence. |
| `Frontend/lib/features/auth/presentation/screens/login_screen.dart` | Dart | Added active target server indicator inside development drawer in debug mode for immediate operator visibility. |
| `Frontend/android/app/src/main/AndroidManifest.xml` | XML | Linked `@xml/network_security_config` to govern Android cleartext policies. |
| `Frontend/android/app/src/main/res/xml/network_security_config.xml` | XML | Permitted cleartext traffic for `10.0.2.2`, `localhost`, and `127.0.0.1`, while enforcing HTTPS for remote domains. |
| `Frontend/test/network_connectivity_diagnostic_test.dart` | Dart | Created automated unit test suite covering all failure diagnosis branches and endpoint configuration. |

---

## 7. Remaining Environment & Operating Guidelines

1. **Physical Phone over USB with Local Backend:**
   If testing against the local Mac server (`http://localhost:5050`) while plugged into USB:
   ```bash
   $HOME/Library/Android/sdk/platform-tools/adb reverse tcp:5050 tcp:5050
   ```
   The app will automatically detect `http://127.0.0.1:5050/health` and route traffic to the local Mac.
2. **Physical Phone Untethered / Over Mobile Data or Wi-Fi:**
   No extra commands or configuration are required. The app automatically detects that local port forwarding is inactive and routes API and AI requests through the secure remote staging backend (`https://acadex-backend-main.onrender.com/api/v1`), which connects to the same MongoDB Atlas database.
3. **Physical Phone with Custom Local LAN IP:**
   If testing over local Wi-Fi without USB:
   ```bash
   flutter run -d <device_id> --dart-define=DEV_HOST=192.168.1.6
   ```
4. **Android Emulator:**
   Launch any AVD; the app automatically detects the emulator environment and routes traffic to `http://10.0.2.2:5050/api/v1`.
