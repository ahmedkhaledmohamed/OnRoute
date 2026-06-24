#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANDROID_DIR="$PROJECT_ROOT/android"
APK_PATH="$ANDROID_DIR/app/build/outputs/apk/debug/app-debug.apk"

FIREBASE_PROJECT="onroute-akm-2026"
FIREBASE_APP="1:392511828543:android:77e424da0d5c8a27d0be8a"
TESTERS="ahmed.khaled.a.mohamed@gmail.com,youssefhassan13@gmail.com,minazakiz@gmail.com,mina.kleid@atlantic-ventures.com"

# Get release notes from argument or default
NOTES="${1:-New build}"

echo "=== Uploading OnRoute Android to Firebase ==="

# Step 1: Build
echo "→ Building debug APK..."
cd "$ANDROID_DIR"
JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null || echo "$HOME/.sdkman/candidates/java/current")
export JAVA_HOME
./gradlew assembleDebug 2>&1 | tail -1

if [ ! -f "$APK_PATH" ]; then
    echo "Error: APK not found"
    exit 1
fi

# Step 2: Upload
echo "→ Uploading to Firebase App Distribution..."
firebase appdistribution:distribute "$APK_PATH" \
    --project "$FIREBASE_PROJECT" \
    --app "$FIREBASE_APP" \
    --release-notes "$NOTES" \
    --testers "$TESTERS" 2>&1 | grep "✔"

echo ""
echo "=== Done! All testers notified ==="
