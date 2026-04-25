cmake_minimum_required(VERSION 3.13)

set(PROJECT_NAME "bclibc_ffi")
project(${PROJECT_NAME} LANGUAGES C CXX)

# packages/bclibc_ffi/src/ → ../../.. → project root
get_filename_component(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)
set(BCLIBC_ROOT "${PROJECT_ROOT}/external/bclibc")

message(STATUS "[bclibc_ffi/android] Project root: ${PROJECT_ROOT}")
message(STATUS "[bclibc_ffi/android] bclibc path:  ${BCLIBC_ROOT}")

if(NOT EXISTS "${BCLIBC_ROOT}")
    message(FATAL_ERROR "bclibc not found at ${BCLIBC_ROOT}")
endif()

if(NOT EXISTS "${BCLIBC_ROOT}/CMakeLists.txt")
    message(FATAL_ERROR "bclibc CMakeLists.txt not found at ${BCLIBC_ROOT}")
endif()

add_subdirectory(
    "${BCLIBC_ROOT}"
    "${CMAKE_CURRENT_BINARY_DIR}/bclibc_ffi_build"
)
