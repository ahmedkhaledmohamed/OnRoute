#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NOTES="${1:-New build}"

echo "=== OnRoute Release ==="
echo "Release notes: $NOTES"
echo ""

# Upload Android to Firebase
echo "--- Android ---"
"$SCRIPT_DIR/upload-firebase.sh" "$NOTES"
echo ""

# Upload iOS to TestFlight
echo "--- iOS ---"
"$SCRIPT_DIR/upload-testflight.sh"
echo ""

echo "=== Both platforms uploaded! ==="
