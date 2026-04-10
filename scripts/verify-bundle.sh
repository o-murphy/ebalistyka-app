#!/usr/bin/env bash
# Verify that a Flutter bundle contains the main executable and required native libraries.
#
# Usage: verify-bundle.sh <bundle_dir> <platform>
#   bundle_dir  — path to the Flutter build output (bundle/)
#   platform    — linux | windows
#
# Exits non-zero if critical files are missing.
set -euo pipefail

BUNDLE_DIR="${1:?Usage: verify-bundle.sh <bundle_dir> <platform>}"
PLATFORM="${2:?Usage: verify-bundle.sh <bundle_dir> <platform>}"

# ── Bundle directory ──────────────────────────────────────────────────────────
if [ ! -d "$BUNDLE_DIR" ]; then
  echo "ERROR: bundle directory not found: $BUNDLE_DIR"
  echo "Searching for executables under build/:"
  find build -maxdepth 8 \( -name "ebalistyka" -o -name "ebalistyka.exe" \) 2>/dev/null || true
  exit 1
fi

# ── Executable ────────────────────────────────────────────────────────────────
if [ "$PLATFORM" = "linux" ]; then
  EXE="$BUNDLE_DIR/ebalistyka"
else
  EXE="$BUNDLE_DIR/ebalistyka.exe"
fi

if [ ! -f "$EXE" ]; then
  echo "ERROR: executable not found: $EXE"
  ls -la "$BUNDLE_DIR/" || true
  exit 1
fi
echo "✓ Executable: $EXE"

# ── Native libraries ──────────────────────────────────────────────────────────
if [ "$PLATFORM" = "linux" ]; then
  SO_COUNT=$(find "$BUNDLE_DIR/lib" -name "*.so" 2>/dev/null | wc -l)
  if [ "$SO_COUNT" -eq 0 ]; then
    echo "ERROR: no .so files in $BUNDLE_DIR/lib/ — native libraries not bundled"
    ls -la "$BUNDLE_DIR/" || true
    exit 1
  fi
  echo "✓ Native libraries ($SO_COUNT .so files):"
  find "$BUNDLE_DIR/lib" -name "*.so" | sort | sed 's/^/  /'

  # Critical: bclibc_ffi
  if ! find "$BUNDLE_DIR/lib" -name "libbclibc_ffi*" | grep -q .; then
    echo "ERROR: libbclibc_ffi not found in lib/ — app will crash on startup"
    exit 1
  fi
  echo "✓ libbclibc_ffi present"

  # Critical: objectbox
  if ! find "$BUNDLE_DIR/lib" -name "libobjectbox*" | grep -q .; then
    echo "ERROR: libobjectbox not found in lib/ — database will not initialize"
    exit 1
  fi
  echo "✓ libobjectbox present"

else
  DLL_COUNT=$(find "$BUNDLE_DIR" -maxdepth 1 -name "*.dll" 2>/dev/null | wc -l)
  if [ "$DLL_COUNT" -eq 0 ]; then
    echo "ERROR: no .dll files in $BUNDLE_DIR — native libraries not bundled"
    ls -la "$BUNDLE_DIR/" || true
    exit 1
  fi
  echo "✓ Native DLLs ($DLL_COUNT files):"
  find "$BUNDLE_DIR" -maxdepth 1 -name "*.dll" | sort | sed 's/^/  /'

  # Critical: bclibc_ffi
  if ! find "$BUNDLE_DIR" -maxdepth 1 -name "bclibc_ffi*" | grep -q .; then
    echo "ERROR: bclibc_ffi.dll not found — app will crash on startup"
    exit 1
  fi
  echo "✓ bclibc_ffi.dll present"
fi

echo "✓ Bundle verified OK"
