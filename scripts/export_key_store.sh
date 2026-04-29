#!/bin/bash
# Script for exporting environment variables for Android APK signing
# Usage: source export_keystore.sh [store_password] [key_password]
#
# Arguments:
#   $1 - keystore password (store password) - required
#   $2 - key password (key password) - optional, uses $1 if not specified

# Path to your keystore file (absolute or relative)
KEYSTORE_PATH="certs/ebalistyka.keystore"
KEY_ALIAS="ebalistyka"

# Get passwords from arguments
KEYSTORE_PASSWORD="${1:-}"
KEY_PASSWORD="${2:-$KEYSTORE_PASSWORD}"  # If key password not specified, use store password

# Check if password was provided
if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo "❌ Error: Keystore password must be provided"
    echo "Usage: source export_keystore.sh <store_password> [key_password]"
    echo "Example: source export_keystore.sh mySecretPass123"
    echo "Or with different passwords: source export_keystore.sh storePass123 keyPass456"
    return 1 2>/dev/null || exit 1
fi

# Check if keystore file exists
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "❌ Error: Keystore file not found at path: $KEYSTORE_PATH"
    echo "Please check the path or create a keystore"
    return 1 2>/dev/null || exit 1
fi

# Export variables for build-android.sh script
export ANDROID_KEYSTORE_BASE64=$(base64 -w0 "$KEYSTORE_PATH")
export ANDROID_KEYSTORE_PASSWORD="$KEYSTORE_PASSWORD"
export ANDROID_KEY_ALIAS="$KEY_ALIAS"
export ANDROID_KEY_PASSWORD="$KEY_PASSWORD"

# Additionally export for key.properties (if needed directly)
export STORE_PASSWORD="$KEYSTORE_PASSWORD"
export KEY_PASSWORD="$KEY_PASSWORD"
export KEY_ALIAS="$KEY_ALIAS"

# Display information (without passwords!)
echo "✅ Android signing environment variables set"
echo "   Keystore: $KEYSTORE_PATH"
echo "   Key alias: $KEY_ALIAS"
echo "   Base64 length: ${#ANDROID_KEYSTORE_BASE64} characters"
echo ""
echo "   Available variables:"
echo "   - ANDROID_KEYSTORE_BASE64"
echo "   - ANDROID_KEYSTORE_PASSWORD"
echo "   - ANDROID_KEY_ALIAS"
echo "   - ANDROID_KEY_PASSWORD"