#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANDROID_DIR="$PROJECT_ROOT/android"
AAB_PATH="$ANDROID_DIR/app/build/outputs/bundle/release/app-release.aab"

echo "=== Building OnRoute Release AAB ==="

# Verify keystore.properties exists
if [ ! -f "$ANDROID_DIR/keystore.properties" ]; then
    echo "Error: keystore.properties not found in android/"
    echo "Create it with: storeFile, storePassword, keyAlias, keyPassword"
    exit 1
fi

# Build
echo "→ Building release AAB..."
cd "$ANDROID_DIR"
JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null || echo "$HOME/.sdkman/candidates/java/current")
export JAVA_HOME
./gradlew bundleRelease 2>&1 | tail -3

if [ ! -f "$AAB_PATH" ]; then
    echo "Error: AAB not found at $AAB_PATH"
    exit 1
fi

SIZE=$(du -h "$AAB_PATH" | cut -f1)
echo ""
echo "=== Done! Release AAB built ==="
echo "→ File: $AAB_PATH"
echo "→ Size: $SIZE"
echo ""
echo "Next steps:"
echo "1. Go to https://play.google.com/console"
echo "2. Select OnRoute → Release → Internal testing"
echo "3. Upload the AAB file above"
echo "4. Add release notes and roll out"
