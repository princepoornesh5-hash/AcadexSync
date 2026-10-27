#!/bin/bash
# ==============================================================================
# ACADEX Android USB Reverse Port Forwarding Utility
# Sets up adb reverse tunnels for ports 5050 (API) and 5001 (AI)
# ==============================================================================

set -euo pipefail

# Locate adb
ADB_BIN="adb"
if ! command -v adb &> /dev/null; then
  if [[ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]]; then
    ADB_BIN="$HOME/Library/Android/sdk/platform-tools/adb"
  else
    echo "❌ Error: 'adb' not found in PATH or Android SDK platform-tools."
    exit 1
  fi
fi

echo "============================================================"
echo "  ACADEX Android USB Reverse Port-Forwarding Setup"
echo "============================================================"
echo "ADB Binary: $ADB_BIN"

# Check connected devices
echo ""
echo "📱 Checking attached Android devices..."
DEVICES=$("$ADB_BIN" devices | grep -v "List" | grep "device$" || true)

if [[ -z "$DEVICES" ]]; then
  echo "⚠️  No authorized Android devices detected via USB."
  echo ""
  echo "Troubleshooting:"
  echo "  1. Connect your Android phone via USB."
  echo "  2. Ensure 'Developer options' and 'USB debugging' are enabled."
  echo "  3. Accept the 'Allow USB debugging?' RSA prompt on the phone screen."
  echo "  4. Note: On a physical phone without USB adb reverse, ACADEX"
  echo "     automatically routes to the secure remote development endpoint:"
  echo "     https://acadex-backend-main.onrender.com/api/v1"
  exit 0
fi

echo "Found attached device(s):"
echo "$DEVICES"
echo ""

# Setup adb reverse for API (5050) and AI (5001)
echo "🔌 Configuring adb reverse tunnels..."
"$ADB_BIN" reverse tcp:5050 tcp:5050
"$ADB_BIN" reverse tcp:5001 tcp:5001

echo ""
echo "Active adb reverse forwards:"
"$ADB_BIN" reverse --list

# Verify local backend health
echo ""
echo "🔍 Checking local ACADEX backend health on http://127.0.0.1:5050/health..."
if curl -s -f http://127.0.0.1:5050/health > /dev/null; then
  echo "✅ Local backend is UP and HEALTHY on port 5050!"
else
  echo "⚠️  Warning: Local backend did not respond on http://127.0.0.1:5050/health."
  echo "    Start the backend using: cd Backend && npm run dev"
fi

echo ""
echo "============================================================"
echo "✅ USB Reverse Setup Complete!"
echo "The connected Android phone can now communicate with"
echo "http://localhost:5050 and http://localhost:5001 through USB."
echo "============================================================"
