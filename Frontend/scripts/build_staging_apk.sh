#!/bin/bash
# ── ACADEX Staging APK Build Script ────────────────────────
# Usage:
#   ./scripts/build_staging_apk.sh <STAGING_API_BASE_URL>
#
# Example:
#   ./scripts/build_staging_apk.sh https://acadex-backend.onrender.com/api/v1
#
# If no argument is provided, defaults to local dev backend:
#   http://localhost:5050/api/v1

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

API_URL="${1:-http://localhost:5050/api/v1}"

echo "============================================================"
echo "  ACADEX Android Staging APK Builder"
echo "============================================================"
echo "  Target API Base URL: ${API_URL}"
echo "  Working Directory:   ${FRONTEND_DIR}"
echo "============================================================"

cd "${FRONTEND_DIR}"

echo ""
echo "🚀 [1/3] Running Flutter clean & dependency retrieval..."
flutter pub get

echo ""
echo "🔍 [2/3] Analyzing frontend code..."
flutter analyze

echo ""
echo "📦 [3/3] Building staging Android APK with compile-time API_BASE_URL..."
flutter build apk --debug \
  --dart-define=API_BASE_URL="${API_URL}"

APK_PATH="${FRONTEND_DIR}/build/app/outputs/flutter-apk/app-debug.apk"

echo ""
echo "============================================================"
echo "✅ BUILD COMPLETE!"
echo "  APK Location: ${APK_PATH}"
echo ""
echo "  To install on connected physical Android device(s):"
echo "    adb install -r \"${APK_PATH}\""
echo ""
echo "  To install on multiple connected devices simultaneously:"
echo "    for dev in \$(adb devices | awk 'NR>1 && \$2==\"device\" {print \$1}'); do"
echo "      echo \"Installing on device: \$dev\""
echo "      adb -s \$dev install -r \"${APK_PATH}\""
echo "    done"
echo "============================================================"
