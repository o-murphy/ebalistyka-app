#!/usr/bin/env bash
# Package a pre-built Flutter Linux bundle into a Flatpak.
#
# Usage: package-flatpak.sh <bundle_dir> <arch_suffix> [build_name] [build_number]
#   bundle_dir   — path to the extracted Flutter Linux bundle
#   arch_suffix  — x86_64 | aarch64
#
# Requirements: flatpak, flatpak-builder, org.gnome.Platform//48 runtime.
# Local setup:
#   sudo apt install flatpak flatpak-builder
#   flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
#   flatpak install --user flathub org.gnome.Platform//48 org.gnome.Sdk//48
set -euo pipefail

BUNDLE_DIR="${1:?Usage: package-flatpak.sh <bundle_dir> <arch_suffix>}"
ARCH_SUFFIX="${2:?}"
BUILD_NAME="${3:-local}"
BUILD_NUMBER="${4:-0}"

APP_ID="io.github.o_murphy.ebalistyka"
MANIFEST="flatpak/${APP_ID}.yml"

if [ ! -f "$MANIFEST" ]; then
  echo "❌ $MANIFEST not found — run from the project root" >&2
  exit 1
fi

# ── Prepare bundle source ─────────────────────────────────────────────────────
rm -rf flatpak/bundle
mkdir -p flatpak/bundle
cp -r "${BUNDLE_DIR}/"* flatpak/bundle/

# Icon (512x512 preferred for Flatpak)
if [ -f "assets/icon_512x512.png" ]; then
  cp "assets/icon_512x512.png" "flatpak/bundle/ebalistyka.png"
elif [ -f "assets/icon.png" ]; then
  cp "assets/icon.png" "flatpak/bundle/ebalistyka.png"
else
  echo "❌ No icon found" >&2
  exit 1
fi

# Copy desktop, metainfo and wrapper into bundle so flatpak-builder can find them
cp "flatpak/${APP_ID}.desktop"      "flatpak/bundle/${APP_ID}.desktop"
cp "flatpak/${APP_ID}.metainfo.xml" "flatpak/bundle/${APP_ID}.metainfo.xml"
cp "flatpak/ebalistyka-wrapper.sh"  "flatpak/bundle/ebalistyka-wrapper.sh"

# Stamp version in metainfo
TODAY=$(date +%Y-%m-%d)
sed -i "s|<release version=\"[^\"]*\" date=\"[^\"]*\"/>|<release version=\"${BUILD_NAME}\" date=\"${TODAY}\"/>|" \
  "flatpak/bundle/${APP_ID}.metainfo.xml"

echo "✓ Bundle prepared (version: ${BUILD_NAME})"

# ── Build ─────────────────────────────────────────────────────────────────────
REPO_DIR=".flatpak-repo"
BUILD_DIR=".flatpak-build"

flatpak-builder \
  --force-clean \
  --disable-rofiles-fuse \
  "$BUILD_DIR" \
  "$MANIFEST"

flatpak build-export "$REPO_DIR" "$BUILD_DIR" stable

# ── Export .flatpak bundle ────────────────────────────────────────────────────
mkdir -p artifacts/flatpak
OUT="artifacts/flatpak/ebalistyka_linux_${ARCH_SUFFIX}.flatpak"

flatpak build-bundle \
  --arch="${ARCH_SUFFIX}" \
  "$REPO_DIR" \
  "$OUT" \
  "$APP_ID" \
  stable

echo "✓ Flatpak: $OUT"

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf "$BUILD_DIR" "$REPO_DIR" flatpak/bundle

echo ""
echo "Artifacts:"
ls -lh artifacts/flatpak/
