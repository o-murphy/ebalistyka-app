#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DB_DIR="${HOME}/.eBallistyka"

echo "========================================="
echo "   ObjectBox Database Manager"
echo "   DB: ${DB_DIR}"
echo "========================================="

if [ -f "${DB_DIR}/data.mdb" ]; then
    echo -e "${GREEN}✅ База даних знайдена!${NC}"
    echo "   Розмір: $(du -sh "${DB_DIR}" | cut -f1)"
else
    echo -e "${YELLOW}⚠️  База даних не знайдена за шляхом ${DB_DIR}${NC}"
    echo "   Запустіть застосунок хоча б раз, щоб створити базу."
    exit 1
fi

echo ""
echo "Запускаємо ObjectBox Admin..."
echo "========================================="
echo "🌐 Відкрийте в браузері: http://localhost:8081"
echo "🔒 Для зупинки натисніть Ctrl+C"
echo "========================================="
echo ""

docker run --rm -it \
  --volume "${DB_DIR}:/db" \
  --user "$(id -u):$(id -g)" \
  --publish 8081:8081 \
  objectboxio/admin:latest
