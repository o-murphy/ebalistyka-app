#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "========================================="
echo "   ObjectBox Database Manager"
echo "========================================="

# Перевіряємо чи існує база даних
if [ -d "objectbox" ] && [ -f "objectbox/data.mdb" ]; then
    echo -e "${GREEN}✅ База даних знайдена!${NC}"
    echo "   Розмір: $(du -sh objectbox | cut -f1)"
    echo "   Записів в Sight: $(dart -c 'print(require("objectbox.g.dart")...' 2>/dev/null || echo "?")"
else
    echo -e "${YELLOW}⚠️  База даних не знайдена!${NC}"
    echo "   Створюємо тестову базу даних..."
    
    # Запускаємо тест для створення бази
    if dart test test/debug_test.dart; then
        echo -e "${GREEN}✅ Базу даних успішно створено!${NC}"
    else
        echo -e "${RED}❌ Помилка при створенні бази даних!${NC}"
        exit 1
    fi
fi

echo ""
echo "Запускаємо ObjectBox Admin..."
echo "========================================="
echo "🌐 Відкрийте в браузері: http://localhost:8081"
echo "🔒 Для зупинки натисніть Ctrl+C"
echo "========================================="
echo ""

# Запускаємо Docker Admin
docker run --rm -it \
  --volume "$(pwd)/objectbox:/db" \
  --user $(id -u):$(id -g) \
  --publish 8081:8081 \
  objectboxio/admin:latest