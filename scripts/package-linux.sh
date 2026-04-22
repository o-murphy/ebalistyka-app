#!/usr/bin/env bash
# Package a Flutter Linux bundle into:
#   1. tar.gz  — extract and run directly, no FUSE required
#   2. AppImage — portable single-file, requires libfuse2
#
# Usage: package-linux.sh <bundle_dir> <arch_suffix> <build_name> <build_number>
#   bundle_dir   — path to Flutter build output (bundle/)
#   arch_suffix  — x86_64 | aarch64
#   build_name   — version string, e.g. 0.1.0-alpha
#   build_number — CI run number or local counter
#
# Outputs both files into ./artifacts/
set -euo pipefail

BUNDLE_DIR="${1:?Usage: package-linux.sh <bundle_dir> <arch_suffix> <build_name> <build_number>}"
ARCH_SUFFIX="${2:?}"
BUILD_NAME="${3:?}"
BUILD_NUMBER="${4:?}"

APPIMAGE_TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${ARCH_SUFFIX}.AppImage"

mkdir -p artifacts

# ── 1. tar.gz ─────────────────────────────────────────────────────────────────
# Runs without FUSE. Users extract and run ./ebalistyka directly.
TAR_NAME="ebalistyka-linux-${ARCH_SUFFIX}-${BUILD_NAME}-${BUILD_NUMBER}.tar.gz"
tar -czf "artifacts/$TAR_NAME" -C "$BUNDLE_DIR" .
echo "✓ tar.gz: artifacts/$TAR_NAME"

# ── 2. AppImage ───────────────────────────────────────────────────────────────
# Portable single-file. Requires libfuse2 on the target machine.
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
  # Convert SVG to PNG (if there is ImageMagick)
  if command -v convert &> /dev/null; then
    convert assets/icon.svg -resize 256x256 /tmp/ebalistyka_icon.png
    ICON_SOURCE="/tmp/ebalistyka_icon.png"
  else
    echo "⚠️  ImageMagick not found, cannot convert SVG to PNG"
  fi
elif [ -f "../assets/icon.png" ]; then
  ICON_SOURCE="../assets/icon.png"
fi

# Copy or create icon
if [ -n "$ICON_SOURCE" ] && [ -f "$ICON_SOURCE" ]; then
  cp "$ICON_SOURCE" "$APPDIR/usr/share/icons/hicolor/256x256/apps/ebalistyka.png"
  echo "✓ Icon copied from $ICON_SOURCE"
else
  # Create minimal icon stub
  printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82' \
    > "$APPDIR/usr/share/icons/hicolor/256x256/apps/ebalistyka.png"
  echo "⚠️  No icon found, using fallback"
fi

# Desktop entry
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

# Symlinks required by AppImageKit
ln -sf usr/share/applications/ebalistyka.desktop "$APPDIR/ebalistyka.desktop"
ln -sf usr/share/icons/hicolor/256x256/apps/ebalistyka.png "$APPDIR/ebalistyka.png"

# AppRun — sets LD_LIBRARY_PATH so the bundled .so files are found
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
APP_DIR="$HERE/usr/share/ebalistyka"
export LD_LIBRARY_PATH="$APP_DIR/lib:$LD_LIBRARY_PATH"
exec "$APP_DIR/ebalistyka" "$@"
EOF
chmod +x "$APPDIR/AppRun"

APPIMAGE_NAME="ebalistyka-linux-${ARCH_SUFFIX}-${BUILD_NAME}-${BUILD_NUMBER}.AppImage"
ARCH="${ARCH_SUFFIX}" /tmp/appimagetool "$APPDIR" "artifacts/$APPIMAGE_NAME"
echo "✓ AppImage: artifacts/$APPIMAGE_NAME"

echo ""
echo "Artifacts:"
ls -lh artifacts/
