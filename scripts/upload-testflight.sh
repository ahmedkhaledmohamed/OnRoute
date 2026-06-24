#!/bin/bash
set -e

# App Store Connect API credentials
API_KEY_ID="532Q5RZF4S"
API_ISSUER_ID="b9178d52-7721-4076-b666-61a81aec07a6"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_DIR="$PROJECT_ROOT/ios"
KEY_PATH="$IOS_DIR/keys/AuthKey_${API_KEY_ID}.p8"
ARCHIVE_PATH="$IOS_DIR/build/Detour.xcarchive"
EXPORT_PATH="$IOS_DIR/build/export"
EXPORT_OPTIONS="$IOS_DIR/ExportOptions.plist"

# Verify key exists
if [ ! -f "$KEY_PATH" ]; then
    echo "Error: API key not found at $KEY_PATH"
    exit 1
fi

# Get current build number
BUILD_NUM=$(grep "CURRENT_PROJECT_VERSION" "$IOS_DIR/project.yml" | grep -o '"[0-9]*"' | tr -d '"')
echo "=== Uploading OnRoute build $BUILD_NUM to TestFlight ==="

# Step 1: Generate project
echo "→ Generating Xcode project..."
cd "$IOS_DIR"
xcodegen generate 2>&1 | tail -1

# Step 2: Archive
echo "→ Archiving..."
xcodebuild archive \
    -project Detour.xcodeproj \
    -scheme Detour \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    -authenticationKeyPath "$KEY_PATH" \
    -authenticationKeyID "$API_KEY_ID" \
    -authenticationKeyIssuerID "$API_ISSUER_ID" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    2>&1 | tail -5

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "Error: Archive failed"
    exit 1
fi

# Step 3: Export and upload
echo "→ Exporting and uploading to App Store Connect..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -authenticationKeyPath "$KEY_PATH" \
    -authenticationKeyID "$API_KEY_ID" \
    -authenticationKeyIssuerID "$API_ISSUER_ID" \
    -allowProvisioningUpdates \
    2>&1 | tail -5

echo ""
echo "=== Done! Build $BUILD_NUM uploaded to TestFlight ==="
echo "Check status: https://appstoreconnect.apple.com"
