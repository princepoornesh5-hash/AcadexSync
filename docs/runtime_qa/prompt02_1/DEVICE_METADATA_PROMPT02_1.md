# ACADEX Runtime Device Metadata (Prompt 02.1)

## Verified Hardware Specifications

Every parameter below was obtained through direct, authoritative ADB query execution on the physical Android test device connected via USB/TLS.

| Parameter | Hardware Value | ADB Command / Source | Prompt 02 Discrepancy |
|---|---|---|---|
| **Device Model** | `motorola edge 60 fusion` | `adb shell getprop ro.product.model` | Matched model name |
| **Manufacturer** | `motorola` | `adb shell getprop ro.product.manufacturer` | - |
| **Android Version** | **Android 16** | `adb shell getprop ro.build.version.release` | **FAILED IN P02**: P02 erroneously reported Android 14 |
| **API Level (SDK)** | **36** (Baklava) | `adb shell getprop ro.build.version.sdk` | **FAILED IN P02**: Erroneously assumed SDK 34 |
| **Build ID** | `W3VE36.21-18` | `adb shell getprop ro.build.display.id` | Live Motorola build verified |
| **Physical Resolution** | `1220 x 2712` px | `adb shell wm size` | Verified exact display dimensions |
| **Physical Density** | `450` dpi | `adb shell wm density` | Verified density factor (2.8125x) |
| **Logical Resolution** | `433.8 x 964.3` dp | Computed (`px / (dpi/160)`) | Standard modern tall phone viewport |
| **Status Bar Inset** | `128` px (~45.5 dp) | `adb shell dumpsys display` / insets | Confirmed top safe area required |
| **Navigation Bar Inset** | `68` px (~24.2 dp) | `adb shell dumpsys display` / insets | Gesture bar bottom inset required |
| **Orientation** | `ROTATION_0` (Portrait) | `adb shell dumpsys input` | Verified standard orientation |
| **ABI Architecture** | `arm64-v8a` | `adb shell getprop ro.product.cpu.abi` | Native 64-bit ARM |
| **Device Serial / Transport**| `adb-ZN4223NKHX-fAo5H4._adb-tls-connect._tcp` | `adb devices -l` | Physical hardware connection |

---

## Observability Environment Verification

- **Local Development Server**: Node.js / Express / TypeScript backend running on `http://127.0.0.1:5050`
- **Reverse Port Forwarding**: `adb reverse tcp:5050 tcp:5050` active and healthy
- **Database Engine**: MongoDB Atlas multi-tenant cluster connected and responding
- **Application Binary**: `app-debug.apk` built and installed natively on physical hardware
