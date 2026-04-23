#!/usr/bin/env bash
# Package a Flutter Linux bundle into:
#   1. tar.gz    → artifacts/portable/ebalistyka_linux_<arch>.tar.gz
#   2. AppImage  → artifacts/appimage/ebalistyka_linux_<arch>.AppImage
#
# Usage: package-linux.sh <bundle_dir> <arch_suffix> [build_name] [build_number]
#   arch_suffix  — x86_64 | aarch64
set -euo pipefail

BUNDLE_DIR="${1:?Usage: package-linux.sh <bundle_dir> <arch_suffix>}"
ARCH_SUFFIX="${2:?}"
BUILD_NAME="${3:-local}"
BUILD_NUMBER="${4:-0}"

APPIMAGE_TOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH_SUFFIX}.AppImage"

# GitHub repo slug — set by GitHub Actions automatically; override locally if needed.
# Used to embed zsync update URL and generate .zsync file.
REPO_SLUG="${GITHUB_REPOSITORY:-}"

if [ -n "$REPO_SLUG" ]; then
  OWNER="${REPO_SLUG%%/*}"
  REPO="${REPO_SLUG##*/}"
  APPIMAGE_FILENAME="ebalistyka_linux_${ARCH_SUFFIX}.AppImage"
  UPDATE_INFO="gh-releases-zsync|${OWNER}|${REPO}|latest|${APPIMAGE_FILENAME}.zsync"
  ZSYNC_URL="https://github.com/${REPO_SLUG}/releases/latest/download/${APPIMAGE_FILENAME}"
else
  UPDATE_INFO=""
  ZSYNC_URL=""
  echo "⚠️  GITHUB_REPOSITORY not set — skipping zsync"
fi

mkdir -p artifacts/portable artifacts/appimage

# ── 1. tar.gz ─────────────────────────────────────────────────────────────────
TAR_OUT="artifacts/portable/ebalistyka_linux_${ARCH_SUFFIX}.tar.gz"
tar -czf "$TAR_OUT" -C "$BUNDLE_DIR" .
echo "✓ tar.gz: $TAR_OUT"

# ── 2. AppImage ───────────────────────────────────────────────────────────────
echo "Downloading appimagetool (${ARCH_SUFFIX})..."
curl -fsSL "$APPIMAGE_TOOL_URL" -o /tmp/appimagetool
chmod +x /tmp/appimagetool

APPDIR="AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/share/ebalistyka"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

cp -r "$BUNDLE_DIR/"* "$APPDIR/usr/share/ebalistyka/"

# Icon lookup
ICON_SOURCE=""
if [ -f "assets/icon.png" ]; then
  ICON_SOURCE="assets/icon.png"
elif [ -f "assets/icon.svg" ]; then
  if command -v convert &> /dev/null; then
    convert assets/icon.svg -resize 256x256 /tmp/ebalistyka_icon.png
    ICON_SOURCE="/tmp/ebalistyka_icon.png"
  else
    echo "⚠️  ImageMagick not found, cannot convert SVG to PNG"
  fi
elif [ -f "../assets/icon.png" ]; then
  ICON_SOURCE="../assets/icon.png"
fi

if [ -n "$ICON_SOURCE" ] && [ -f "$ICON_SOURCE" ]; then
  cp "$ICON_SOURCE" "$APPDIR/usr/share/icons/hicolor/256x256/apps/ebalistyka.png"
  echo "✓ Icon copied from $ICON_SOURCE"
else
  printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82' \
    > "$APPDIR/usr/share/icons/hicolor/256x256/apps/ebalistyka.png"
  echo "⚠️  No icon found, using fallback"
fi

cat > "$APPDIR/usr/share/applications/ebalistyka.desktop" <<'EOF'
[Desktop Entry]
Name=eBalistyka
Comment=Ballistic calculator
Exec=ebalistyka
Icon=ebalistyka
Type=Application
Categories=Utility;Science;
StartupWMClass=ebalistyka
EOF

ln -sf usr/share/applications/ebalistyka.desktop "$APPDIR/ebalistyka.desktop"
ln -sf usr/share/icons/hicolor/256x256/apps/ebalistyka.png "$APPDIR/ebalistyka.png"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
APP_DIR="$HERE/usr/share/ebalistyka"
export LD_LIBRARY_PATH="$APP_DIR/lib:$LD_LIBRARY_PATH"
exec "$APP_DIR/ebalistyka" "$@"
EOF
chmod +x "$APPDIR/AppRun"

APPIMAGE_OUT="artifacts/appimage/ebalistyka_linux_${ARCH_SUFFIX}.AppImage"

if [ -n "$UPDATE_INFO" ]; then
  ARCH="${ARCH_SUFFIX}" /tmp/appimagetool --updateinformation "$UPDATE_INFO" "$APPDIR" "$APPIMAGE_OUT"
else
  ARCH="${ARCH_SUFFIX}" /tmp/appimagetool "$APPDIR" "$APPIMAGE_OUT"
fi
echo "✓ AppImage: $APPIMAGE_OUT"

# Generate .zsync for AppImageUpdate (zsync2)
if [ -n "$ZSYNC_URL" ]; then
  if command -v zsyncmake &>/dev/null; then
    zsyncmake -u "$ZSYNC_URL" -o "${APPIMAGE_OUT}.zsync" "$APPIMAGE_OUT"
    echo "✓ zsync:    ${APPIMAGE_OUT}.zsync"
  else
    echo "⚠️  zsyncmake not found — install zsync package"
  fi
fi

echo ""
echo "Artifacts:"
ls -lh artifacts/portable/ artifacts/appimage/
