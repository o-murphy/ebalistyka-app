.PHONY: native ffigen test format clean objectbox objectbox-setup objectbox-clean run run-clean unit gen

# Cross-platform helpers
ifeq ($(OS),Windows_NT)
  NPROC   := $(NUMBER_OF_PROCESSORS)
  RM_DIR  := cmake -E remove_directory
  # getApplicationSupportDirectory() on Windows → %APPDATA%\<company>\<app>\data
  # Flutter uses the BINARY_NAME from CMakeLists.txt ("ebalistyka")
  DB_DIR  := $(APPDATA)\ebalistyka\ebalistyka
else
  NPROC   := $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
  RM_DIR  := rm -rf
  UNAME_S := $(shell uname -s)
  ifeq ($(UNAME_S),Darwin)
    # getApplicationSupportDirectory() on macOS → ~/Library/Application Support/<bundle_id>
    DB_DIR := $(HOME)/Library/Application Support/com.ballistics.ebalistyka
  else
    # getApplicationSupportDirectory() on Linux → $XDG_DATA_HOME/<bundle_id>
    DB_DIR := $(or $(XDG_DATA_HOME),$(HOME)/.local/share)/com.ballistics.ebalistyka
  endif
endif

# Build the native shared library via CMake (still builds from external/bclibc)
native:
	cmake -S external/bclibc -B build/bclibc -DCMAKE_BUILD_TYPE=Release
	cmake --build build/bclibc --parallel $(NPROC)

# Re-generate Dart FFI bindings from the C header (now in the package)
# Requires LLVM/Clang installed:
#   Windows: winget install LLVM  (then restart terminal)
#   Linux:   sudo apt install libclang-dev clang
#   macOS:   brew install llvm
ffigen:
	cd packages/bclibc_ffi && dart run ffigen --config ffigen.yaml

objectbox-setup:
	cd packages/ebalistyka_db && bash <(curl -s https://raw.githubusercontent.com/objectbox/objectbox-dart/main/install.sh)

objectbox:
	cd packages/ebalistyka_db && dart run build_runner build

gen:
	cd packages/ebalistyka_db && dart run build_runner build --delete-conflicting-outputs

objectbox-clean:
	cd packages/ebalistyka_db && dart run build_runner clean

objectbox-admin:
	cd packages/ebalistyka_db && ./admin.sh

# Run all tests (native must be built first)
test: native
	flutter analyze && flutter test 2>&1

format:
	dart format lib test \
		packages/bclibc_ffi/lib \
		packages/ebalistyka_db/lib \
		packages/reticle_gen/lib \
		packages/reticle_gen/bin

run:
	flutter run

run-clean:
ifeq ($(OS),Windows_NT)
	-if exist "$(DB_DIR)" rmdir /s /q "$(DB_DIR)"
else
	-$(RM_DIR) "$(DB_DIR)"
endif
	flutter run

# Run only unit tests (no native dependency)
unit:
	dart test test/core/solver/unit_test.dart

clean:
	$(RM_DIR) build/bclibc
	$(RM_DIR) packages/bclibc_ffi/lib/ffi/*.g.dart
