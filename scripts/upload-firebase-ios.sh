#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_DIR="$PROJECT_ROOT/ios"
KEY_PATH="$IOS_DIR/keys/AuthKey_532Q5RZF4S.p8"
ARCHIVE_PATH="$IOS_DIR/build/Detour.xcarchive"
EXPORT_PATH="$IOS_DIR/build/adhoc"

FIREBASE_PROJECT="onroute-akm-2026"
FIREBASE_APP="1:392511828543:ios:a836dbb12ff309eed0be8a"
TESTERS="ahmed.khaled.a.mohamed@gmail.com,youssefhassan13@gmail.com,minazakiz@gmail.com,mina.kleid@atlantic-ventures.com"

NOTES="${1:-New iOS build}"

echo "=== Uploading OnRoute iOS to Firebase ==="

cd "$IOS_DIR"
xcodegen generate 2>&1 | tail -1

echo "→ Archiving..."
xcodebuild archive \
    -project Detour.xcodeproj \
    -scheme Detour \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    -authenticationKeyPath "$KEY_PATH" \
    -authenticationKeyID 532Q5RZF4S \
    -authenticationKeyIssuerID b9178d52-7721-4076-b666-61a81aec07a6 \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=VMXQN9K3P2 \
    2>&1 | tail -3

echo "→ Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$IOS_DIR/ExportOptions-adhoc.plist" \
    -authenticationKeyPath "$KEY_PATH" \
    -authenticationKeyID 532Q5RZF4S \
    -authenticationKeyIssuerID b9178d52-7721-4076-b666-61a81aec07a6 \
    -allowProvisioningUpdates \
    2>&1 | tail -3

echo "→ Uploading to Firebase..."
firebase appdistribution:distribute "$EXPORT_PATH/Detour.ipa" \
    --project "$FIREBASE_PROJECT" \
    --app "$FIREBASE_APP" \
    --release-notes "$NOTES" \
    --testers "$TESTERS" 2>&1 | grep "✔"

echo ""
echo "=== Done! iOS uploaded to Firebase ==="
