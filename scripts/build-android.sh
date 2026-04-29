#!/usr/bin/env bash
# Build Flutter Android APKs and place them in artifacts/.
#
# Usage:
#   build-android.sh <build_name> <build_number> [--fat]
#
# Arguments:
#   build_name    Version string, e.g. "1.2.3" or "v1.2.3-beta".  "v" prefix is stripped.
#   build_number  Integer build number (git rev-list --count HEAD — monotonically increasing).
#   --fat         Build a single fat APK instead of per-ABI split (optional).
#
# Signing (optional — falls back to debug key if not set):
#   ANDROID_KEYSTORE_BASE64      Base64-encoded .jks/.p12 keystore file.
#   ANDROID_KEYSTORE_PASSWORD    Keystore (store) password.
#   ANDROID_KEY_ALIAS            Key alias inside the keystore.
#   ANDROID_KEY_PASSWORD         Key password.
#
# Outputs:
#   artifacts/ebalistyka_android_arm64.apk
#   artifacts/ebalistyka_android_armeabi_v7a.apk
#   artifacts/ebalistyka_android_x86_64.apk
#   — or —
#   artifacts/ebalistyka_android.apk          (when --fat)

set -euo pipefail

BUILD_NAME="${1:-0.1.0-dev}"
BUILD_NUMBER="${2:-0}"
FAT="${3:-}"

# Strip leading 'v'
BUILD_NAME="${BUILD_NAME#v}"
# Strip pre-release suffix for versionCode compatibility: "1.2.3-beta" → "1.2.3"
BASE=$(echo "$BUILD_NAME" | sed 's/-.*//')

# ── Pubspec version ──────────────────────────────────────────────────────────
sed -i "s/^version:.*/version: ${BASE}+${BUILD_NUMBER}/" pubspec.yaml
echo "pubspec version → ${BASE}+${BUILD_NUMBER}"

# ── Android signing ──────────────────────────────────────────────────────────
if [ -n "${ANDROID_KEYSTORE_BASE64:-}" ]; then
    echo "Setting up Android release signing…"
    echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > android/ebalistyka.keystore
    cat > android/key.properties <<EOF
storePassword=${ANDROID_KEYSTORE_PASSWORD}
keyPassword=${ANDROID_KEY_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
storeFile=../ebalistyka.keystore
EOF
    echo "Keystore written → android/ebalistyka.keystore  (alias: ${ANDROID_KEY_ALIAS})"
else
    echo "ANDROID_KEYSTORE_BASE64 not set — using debug signing"
fi

# ── Build ────────────────────────────────────────────────────────────────────
if [ "$FAT" = "--fat" ]; then
    flutter build apk --release
else
    flutter build apk --release --split-per-abi
fi

# ── Package ──────────────────────────────────────────────────────────────────
mkdir -p artifacts

if [ "$FAT" = "--fat" ]; then
    cp build/app/outputs/flutter-apk/app-release.apk \
       artifacts/ebalistyka_android.apk
else
    cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   artifacts/ebalistyka_android_arm64.apk
    cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk artifacts/ebalistyka_android_armeabi_v7a.apk
    cp build/app/outputs/flutter-apk/app-x86_64-release.apk      artifacts/ebalistyka_android_x86_64.apk
fi

echo "=== APK artifacts ==="
ls -lh artifacts/
