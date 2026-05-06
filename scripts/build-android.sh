#!/usr/bin/env bash
# Build Flutter Android APKs (per-ABI split + universal fat) and place them in artifacts/.
#
# Usage:
#   build-android.sh <build_name> <build_number>
#
# Arguments:
#   build_name    Version string, e.g. "1.2.3" or "1.2.3-beta.1".  "v" prefix is stripped.
#                 Pre-release suffix is preserved as Android versionName.
#   build_number  Integer build number (git rev-list --count --first-parent HEAD — monotonically increasing).
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
#   artifacts/ebalistyka_android_universal.apk

set -euo pipefail

BUILD_NAME="${1:-0.1.0-dev}"
BUILD_NUMBER="${2:-0}"

# Strip leading 'v'
BUILD_NAME="${BUILD_NAME#v}"

# ── Cleanup trap ─────────────────────────────────────────────────────────────
cleanup() {
    rm -f android/ebalistyka.keystore android/key.properties
}
trap cleanup EXIT

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

# ── Build per-ABI split APKs ─────────────────────────────────────────────────
flutter build apk --release --split-per-abi \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER"

# Copy split APKs immediately — Gradle stale-output cleanup in the next build
# may remove files produced by a differently-configured assembleRelease run.
mkdir -p artifacts
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   artifacts/ebalistyka_android_arm64.apk
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk artifacts/ebalistyka_android_armeabi_v7a.apk
cp build/app/outputs/flutter-apk/app-x86_64-release.apk      artifacts/ebalistyka_android_x86_64.apk

# ── Build universal (fat) APK ────────────────────────────────────────────────
flutter build apk --release \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER"

cp build/app/outputs/flutter-apk/app-release.apk artifacts/ebalistyka_android_universal.apk

echo "=== APK artifacts ==="
ls -lh artifacts/
