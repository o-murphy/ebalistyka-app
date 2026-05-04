#!/usr/bin/env bash
# Build Flutter macOS app (unsigned) and package it as a zip.
#
# Usage:
#   build-macos.sh [build_name] [build_number]
#
# Arguments:
#   build_name    Version string, e.g. "1.2.3" or "v1.2.3-beta". "v" prefix is stripped.
#   build_number  Integer build number (defaults to git rev-list count).
#
# Prerequisites:
#   - macOS with Xcode command-line tools installed
#   - Flutter SDK on PATH
#   - CocoaPods installed (gem install cocoapods)
#   - git submodule update --init --recursive (for external/bclibc)
#
# Outputs:
#   artifacts/ebalistyka_macos_<build_name>.zip

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

echo "→ Building macOS (no-codesign) ${BUILD_NAME}+${BUILD_NUMBER}..."
flutter build macos --release --no-codesign \
  --build-name="$BASE" \
  --build-number="$BUILD_NUMBER"

APP_PATH=$(find build/macos/Build/Products/Release -name "*.app" -maxdepth 1 | head -1)
if [ -z "$APP_PATH" ]; then
  echo "Error: No .app bundle found in build/macos/Build/Products/Release/"
  exit 1
fi

APP_NAME=$(basename "$APP_PATH" .app)
OUT="artifacts/ebalistyka_macos_${BUILD_NAME}.zip"

echo "→ Packaging ${APP_PATH}..."
# ditto preserves resource forks and HFS+ metadata; fall back to zip if unavailable.
if command -v ditto &>/dev/null; then
  ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$OUT"
else
  (cd "$(dirname "$APP_PATH")" && zip -qr "$(pwd)/../../../${OUT}" "${APP_NAME}.app")
fi

echo ""
echo "=== macOS artifacts ==="
ls -lh artifacts/
echo ""
echo "Install note: right-click the .app → Open to bypass Gatekeeper on first launch."
echo "  Or: xattr -d com.apple.quarantine \"${APP_NAME}.app\""
