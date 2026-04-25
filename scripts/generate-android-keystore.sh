#!/usr/bin/env bash
# Generate an Android release keystore and produce everything needed for CI.
#
# Usage:
#   ./scripts/generate-android-keystore.sh [--password <pwd>] [--alias <alias>] [--dn <dn>]
#
# Options:
#   --password  Keystore + key password  (default: prompted interactively)
#   --alias     Key alias                (default: ebalistyka)
#   --dn        Distinguished Name       (default: CN=o-murphy)
#
# Outputs (all gitignored):
#   android/ebalistyka.keystore      — keep this safe, never lose it
#   android/key.properties           — used by build.gradle.kts for local builds
#   certs/android_keystore_base64.txt  — paste into ANDROID_KEYSTORE_BASE64 CI secret
#   certs/android_secrets.txt          — all four secrets ready to copy-paste

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Defaults ─────────────────────────────────────────────────────────────────
PASSWORD=""
ALIAS="ebalistyka"
DN="CN=o-murphy"

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --password) PASSWORD="$2"; shift 2 ;;
        --alias)    ALIAS="$2";    shift 2 ;;
        --dn)       DN="$2";       shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ── Prompt for password if not provided ──────────────────────────────────────
if [ -z "$PASSWORD" ]; then
    read -rsp "Keystore password: " PASSWORD; echo
    read -rsp "Confirm password:  " PASSWORD2; echo
    if [ "$PASSWORD" != "$PASSWORD2" ]; then
        echo "Passwords do not match." >&2
        exit 1
    fi
fi

if [ ${#PASSWORD} -lt 6 ]; then
    echo "Password must be at least 6 characters." >&2
    exit 1
fi

# ── Check keytool ─────────────────────────────────────────────────────────────
if ! command -v keytool &>/dev/null; then
    echo "keytool not found. Install a JDK (e.g. openjdk-17-jdk)." >&2
    exit 1
fi

# ── Paths ─────────────────────────────────────────────────────────────────────
CERTS_DIR="$ROOT_DIR/certs"
KEYSTORE="$ROOT_DIR/android/ebalistyka.keystore"
KEY_PROPS="$ROOT_DIR/android/key.properties"
BASE64_OUT="$CERTS_DIR/android_keystore_base64.txt"
SECRETS_OUT="$CERTS_DIR/android_secrets.txt"

mkdir -p "$CERTS_DIR"

# ── Generate keystore ─────────────────────────────────────────────────────────
echo "Generating keystore…"
keytool -genkey -v \
    -keystore "$KEYSTORE" \
    -alias    "$ALIAS" \
    -keyalg   RSA \
    -keysize  2048 \
    -validity 10000 \
    -dname    "$DN" \
    -storepass "$PASSWORD" \
    -keypass   "$PASSWORD" \
    -storetype JKS 2>/dev/null

echo "Keystore → $KEYSTORE"

# ── Write key.properties for local gradle builds ──────────────────────────────
cat > "$KEY_PROPS" <<EOF
storePassword=${PASSWORD}
keyPassword=${PASSWORD}
keyAlias=${ALIAS}
storeFile=../ebalistyka.keystore
EOF

echo "key.properties → $KEY_PROPS"

# ── Copy keystore to certs/ and export Base64 ────────────────────────────────
cp "$KEYSTORE" "$CERTS_DIR/ebalistyka.keystore"
base64 -w0 "$KEYSTORE" > "$BASE64_OUT"
echo "Keystore copy → $CERTS_DIR/ebalistyka.keystore"
echo "Base64        → $BASE64_OUT"

# ── Write secrets summary file ────────────────────────────────────────────────
cat > "$SECRETS_OUT" <<EOF
=== GITHUB SECRETS (Settings → Secrets and variables → Actions) ===

ANDROID_KEYSTORE_BASE64   = $(cat "$BASE64_OUT")

ANDROID_KEYSTORE_PASSWORD = ${PASSWORD}

ANDROID_KEY_ALIAS         = ${ALIAS}

ANDROID_KEY_PASSWORD      = ${PASSWORD}
EOF

echo "Secrets file  → $SECRETS_OUT"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== LOCAL BUILD ==="
echo "key.properties is in place — 'flutter build apk --release' will sign automatically."
echo ""
echo "=== GITHUB SECRETS ==="
echo "See certs/android_secrets.txt or add manually:"
echo ""
echo "  ANDROID_KEYSTORE_BASE64    = content of certs/android_keystore_base64.txt"
echo "  ANDROID_KEYSTORE_PASSWORD  = ${PASSWORD}"
echo "  ANDROID_KEY_ALIAS          = ${ALIAS}"
echo "  ANDROID_KEY_PASSWORD       = ${PASSWORD}"
echo ""
echo "WARNING: Keep certs/ebalistyka.keystore safe — back it up outside the repo."
echo "         If you lose it you cannot update the app on users' devices."
