cmake_minimum_required(VERSION 3.13)
project(bclibc_ffi LANGUAGES CXX)

# ============================================================================
# Paths to the embedded bclibc library (py-ballisticcalc submodule)
# ============================================================================

set(BCLIBC_ROOT
    "${CMAKE_CURRENT_SOURCE_DIR}/../py-ballisticcalc/py_ballisticcalc.exts/py_ballisticcalc_exts")
set(BCLIBC_INCLUDE "${BCLIBC_ROOT}/include")
set(BCLIBC_SRC     "${BCLIBC_ROOT}/src")

# Source files (py_bind.cpp excluded – it is Cython-only)
set(BCLIBC_SOURCES
    "${BCLIBC_SRC}/base_types.cpp"
    "${BCLIBC_SRC}/engine.cpp"
    "${BCLIBC_SRC}/traj_data.cpp"
    "${BCLIBC_SRC}/traj_filter.cpp"
    "${BCLIBC_SRC}/euler.cpp"
    "${BCLIBC_SRC}/rk4.cpp"
    "${BCLIBC_SRC}/interp.cpp"
)

# ============================================================================
# Shared library target
# ============================================================================

add_library(bclibc_ffi SHARED
    "${CMAKE_CURRENT_SOURCE_DIR}/bclibc_ffi.cpp"
    ${BCLIBC_SOURCES}
)

target_include_directories(bclibc_ffi PRIVATE
    "${BCLIBC_INCLUDE}"
    "${CMAKE_CURRENT_SOURCE_DIR}"
)

set_property(TARGET bclibc_ffi PROPERTY CXX_STANDARD 17)
set_property(TARGET bclibc_ffi PROPERTY CXX_STANDARD_REQUIRED ON)
set_property(TARGET bclibc_ffi PROPERTY POSITION_INDEPENDENT_CODE ON)

target_compile_options(bclibc_ffi PRIVATE
    "$<$<NOT:$<CONFIG:Debug>>:-O3>"
    "$<$<CONFIG:Debug>:-O0;-g>"
)

# Strip internal symbols on non-Debug builds to keep the .so lean
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
    target_link_options(bclibc_ffi PRIVATE
        "$<$<CXX_COMPILER_ID:GNU,Clang>:-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/bclibc_ffi.version>"
    )
endif()
