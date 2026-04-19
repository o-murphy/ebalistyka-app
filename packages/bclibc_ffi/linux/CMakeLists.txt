# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.13)

# Project-level configuration.
set(PROJECT_NAME "bclibc_ffi")
project(${PROJECT_NAME} LANGUAGES C CXX)

# ============================================================================
# bclibc_ffi – thin C wrapper over the embedded bclibc ballistics engine
# ============================================================================

# Find the project root
# Current path: linux/flutter/ephemeral/.plugin_symlinks/bclibc_ffi/linux/
# Go up 6 levels to the project root
get_filename_component(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../.." ABSOLUTE)
set(BCLIBC_ROOT "${PROJECT_ROOT}/external/bclibc")

# Diagnostics (can be disabled after debugging)
message(STATUS "Project root: ${PROJECT_ROOT}")
message(STATUS "bclibc path: ${BCLIBC_ROOT}")

# Existence check
if(NOT EXISTS "${BCLIBC_ROOT}")
    message(FATAL_ERROR "bclibc not found at ${BCLIBC_ROOT}")
endif()

if(NOT EXISTS "${BCLIBC_ROOT}/CMakeLists.txt")
    message(FATAL_ERROR "bclibc CMakeLists.txt not found at ${BCLIBC_ROOT}")
endif()

# Add the bclibc subdirectory
add_subdirectory(
    "${BCLIBC_ROOT}"
    "${CMAKE_CURRENT_BINARY_DIR}/bclibc_ffi_build"
)

# List of absolute paths to libraries that should be bundled with the plugin.
set(bclibc_ffi_bundled_libraries
    $<TARGET_FILE:bclibc_ffi>
    PARENT_SCOPE
)