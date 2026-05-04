#!/usr/bin/env bash
# Build Flutter iOS app (unsigned) and package it as a sideloadable .ipa.
#
# Usage:
#   build-ios.sh [build_name] [build_number]
#
# Arguments:
#   build_name    Version string, e.g. "1.2.3" or "v1.2.3-beta". "v" prefix is stripped.
#   build_number  Integer build number (defaults to git rev-list count).
#
# Prerequisites:
#   - macOS with Xcode and iOS SDK installed
#   - Flutter SDK on PATH
#   - CocoaPods installed (gem install cocoapods)
#   - git submodule update --init --recursive (for external/bclibc)
#
# Outputs:
#   artifacts/ebalistyka_ios_<build_name>.ipa
#
# Sideload options (no Apple Developer account required):
#   - AltStore  : https://altstore.io  (free Apple ID, re-sign every 7 days)
#   - Sideloadly: https://sideloadly.io (same)
#   - TrollStore: no re-sign needed, device-dependent (iOS 14–17)

set -euo pipefail

BUILD_NAME="${1:-}"
BUILD_NUMBER="${2:-}"

if [ -z "$BUILD_NAME" ]; then
  BUILD_NAME=$(grep '^version:' pubspec.yaml | sed 's/version:[[:space:]]*//' | sed 's/+.*//')
fi
BUILD_NAME="${BUILD_NAME#v}"
BASE=$(echo "$BUILD_NAME" | sed 's/-.*//')

if [ -z "$BUILD_NUMBER" ]; then
  BUILD_NUMBER=$(git rev-list --count --first-parent HEAD)
fi

mkdir -p artifacts

echo "→ Checking git submodule (external/bclibc)..."
if [ ! -f "external/bclibc/CMakeLists.txt" ]; then
  echo "  Initializing submodule..."
  git submodule update --init --recursive
fi

echo "→ Building iOS (no-codesign) ${BUILD_NAME}+${BUILD_NUMBER}..."
flutter build ios --release --no-codesign \
  --build-name="$BASE" \
  --build-number="$BUILD_NUMBER"

APP_PATH=$(find build/ios/iphoneos -name "*.app" -maxdepth 1 | head -1)
if [ -z "$APP_PATH" ]; then
  echo "Error: No .app bundle found in build/ios/iphoneos/"
  echo "Tip: ensure Xcode is installed and 'xcode-select --install' has been run."
  exit 1
fi

echo "→ Packaging ${APP_PATH} as .ipa..."
PAYLOAD_DIR="$(mktemp -d)/Payload"
mkdir -p "$PAYLOAD_DIR"
cp -r "$APP_PATH" "$PAYLOAD_DIR/"

OUT="artifacts/ebalistyka_ios_${BUILD_NAME}.ipa"
(cd "$(dirname "$PAYLOAD_DIR")" && zip -qr "$(pwd -P)/../../../../${OUT}" Payload/)
rm -rf "$(dirname "$PAYLOAD_DIR")"

echo ""
echo "=== iOS artifacts ==="
ls -lh artifacts/
echo ""
echo "Install via:"
echo "  AltStore / Sideloadly: drag the .ipa file into the app (re-sign every 7 days)"
echo "  TrollStore           : use TrollInstaller or copy .ipa to Files and open with TrollStore"
