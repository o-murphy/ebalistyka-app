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
    echo -e "${GREEN}✅ Database found!${NC}"
    echo "Size: $(du -sh "${DB_DIR}" | cut -f1)"
else
    echo -e "${YELLOW}⚠️ Database not found at path ${DB_DIR}${NC}"
    echo " Run the application at least once to create the database."
    exit 1
fi

echo ""
echo "Launching ObjectBox Admin..."
echo "========================================="
echo "🌐 Open in browser: http://localhost:8081"
echo "🔒 To stop, press Ctrl+C"
echo "========================================="
echo ""

docker run --rm -it \
  --volume "${DB_DIR}:/db" \
  --user "$(id -u):$(id -g)" \
  --publish 8081:8081 \
  objectboxio/admin:latest
