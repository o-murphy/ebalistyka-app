#!/bin/bash
# Скрипт для експорту змінних оточення для підписання Android APK
# Використання: source export_keystore.sh [пароль_сховища] [пароль_ключа]
#
# Аргументи:
#   $1 - пароль для keystore (store password) - обов'язковий
#   $2 - пароль для ключа (key password) - опціональний, якщо не вказано - використовує $1

# Шлях до вашого keystore файлу (абсолютний або відносний)
KEYSTORE_PATH="certs/ebalistyka.keystore"
KEY_ALIAS="ebalistyka"

# Отримуємо паролі з аргументів
KEYSTORE_PASSWORD="${1:-}"
KEY_PASSWORD="${2:-$KEYSTORE_PASSWORD}"  # Якщо ключ не вказано, використовуємо пароль сховища

# Перевірка, чи передано пароль
if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo "❌ Помилка: Необхідно вказати пароль keystore"
    echo "Використання: source export_keystore.sh <store_password> [key_password]"
    echo "Приклад: source export_keystore.sh mySecretPass123"
    echo "Або з різними паролями: source export_keystore.sh storePass123 keyPass456"
    return 1 2>/dev/null || exit 1
fi

# Перевірка, чи існує файл keystore
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "❌ Помилка: Keystore файл не знайдено за шляхом: $KEYSTORE_PATH"
    echo "Будь ласка, перевірте шлях або створіть keystore"
    return 1 2>/dev/null || exit 1
fi

# Експортуємо змінні для скрипту build-android.sh
export ANDROID_KEYSTORE_BASE64=$(base64 -w0 "$KEYSTORE_PATH")
export ANDROID_KEYSTORE_PASSWORD="$KEYSTORE_PASSWORD"
export ANDROID_KEY_ALIAS="$KEY_ALIAS"
export ANDROID_KEY_PASSWORD="$KEY_PASSWORD"

# Додатково експортуємо для key.properties (якщо потрібно напряму)
export STORE_PASSWORD="$KEYSTORE_PASSWORD"
export KEY_PASSWORD="$KEY_PASSWORD"
export KEY_ALIAS="$KEY_ALIAS"

# Показуємо інформацію (без паролів!)
echo "✅ Змінні оточення для підписання Android встановлено"
echo "   Keystore: $KEYSTORE_PATH"
echo "   Key alias: $KEY_ALIAS"
echo "   Base64 довжина: ${#ANDROID_KEYSTORE_BASE64} символів"
echo ""
echo "   Доступні змінні:"
echo "   - ANDROID_KEYSTORE_BASE64"
echo "   - ANDROID_KEYSTORE_PASSWORD"
echo "   - ANDROID_KEY_ALIAS"
echo "   - ANDROID_KEY_PASSWORD"