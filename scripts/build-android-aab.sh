#!/usr/bin/env bash
# Build Flutter Android App Bundle (AAB) and place it in artifacts/.
#
# Usage:
#   build-android-aab.sh <build_name> <build_number>
#
# Arguments:
#   build_name    Version string, e.g. "1.2.3" or "v1.2.3-beta".  "v" prefix is stripped.
#   build_number  Integer build number (git rev-list --count --first-parent HEAD — monotonically increasing).
#
# Signing (optional — falls back to debug key if not set):
#   ANDROID_KEYSTORE_BASE64      Base64-encoded .jks/.p12 keystore file.
#   ANDROID_KEYSTORE_PASSWORD    Keystore (store) password.
#   ANDROID_KEY_ALIAS            Key alias inside the keystore.
#   ANDROID_KEY_PASSWORD         Key password.
#
# Outputs:
#   artifacts/ebalistyka_android.aab

set -euo pipefail

BUILD_NAME="${1:-0.1.0-dev}"
BUILD_NUMBER="${2:-0}"

# Strip leading 'v'
BUILD_NAME="${BUILD_NAME#v}"
# Strip pre-release suffix for versionCode compatibility: "1.2.3-beta" → "1.2.3"
BASE=$(echo "$BUILD_NAME" | sed 's/-.*//')

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

# ── Build AAB ────────────────────────────────────────────────────────────────
flutter build appbundle --release \
  --build-name="$BASE" \
  --build-number="$BUILD_NUMBER"

# ── Package ──────────────────────────────────────────────────────────────────
mkdir -p artifacts

cp build/app/outputs/bundle/release/app-release.aab artifacts/ebalistyka_android.aab

echo "=== AAB artifacts ==="
ls -lh artifacts/
