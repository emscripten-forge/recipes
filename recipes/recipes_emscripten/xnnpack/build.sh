#!/bin/bash
set -exuo pipefail

# Set default values for potentially unset variables
EM_FORGE_SIDE_MODULE_CFLAGS="${EM_FORGE_SIDE_MODULE_CFLAGS:-}"
EM_FORGE_SIDE_MODULE_LDFLAGS="${EM_FORGE_SIDE_MODULE_LDFLAGS:-}"
CFLAGS="${CFLAGS:-}"
CXXFLAGS="${CXXFLAGS:-}"
LDFLAGS="${LDFLAGS:-}"

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

mkdir -p build
cd build

emcmake cmake -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DXNNPACK_LIBRARY_TYPE=static \
    -DXNNPACK_BUILD_TESTS=OFF \
    -DXNNPACK_BUILD_BENCHMARKS=OFF \
    -DXNNPACK_BUILD_ALL_MICROKERNELS=OFF \
    -DXNNPACK_USE_SYSTEM_LIBS=OFF \
    -DXNNPACK_ENABLE_ASSEMBLY=OFF \
    -DXNNPACK_ENABLE_KLEIDIAI=OFF \
    ..

ninja install

# XNNPACK does not install a CMake config file, so create a minimal one
# for downstream consumers using find_package(XNNPACK CONFIG).
mkdir -p "${PREFIX}/lib/cmake/xnnpack"
cat > "${PREFIX}/lib/cmake/xnnpack/XNNPACKConfig.cmake" <<'EOF'
get_filename_component(_XNNPACK_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_XNNPACK_IMPORT_PREFIX "${_XNNPACK_IMPORT_PREFIX}" PATH)
get_filename_component(_XNNPACK_IMPORT_PREFIX "${_XNNPACK_IMPORT_PREFIX}" PATH)
get_filename_component(_XNNPACK_IMPORT_PREFIX "${_XNNPACK_IMPORT_PREFIX}" PATH)

set(_XNNPACK_INCLUDE_DIR "${_XNNPACK_IMPORT_PREFIX}/include")
set(_XNNPACK_LIB_DIR "${_XNNPACK_IMPORT_PREFIX}/lib")

if(NOT TARGET XNNPACK::xnnpack)
    add_library(XNNPACK::xnnpack STATIC IMPORTED)
    set_target_properties(XNNPACK::xnnpack PROPERTIES
        IMPORTED_LOCATION "${_XNNPACK_LIB_DIR}/libXNNPACK.a"
        INTERFACE_INCLUDE_DIRECTORIES "${_XNNPACK_INCLUDE_DIR}"
    )
endif()

if(NOT TARGET XNNPACK::xnnpack-microkernels-prod)
    add_library(XNNPACK::xnnpack-microkernels-prod STATIC IMPORTED)
    set_target_properties(XNNPACK::xnnpack-microkernels-prod PROPERTIES
        IMPORTED_LOCATION "${_XNNPACK_LIB_DIR}/libxnnpack-microkernels-prod.a"
    )
endif()

unset(_XNNPACK_IMPORT_PREFIX)
unset(_XNNPACK_INCLUDE_DIR)
unset(_XNNPACK_LIB_DIR)
EOF

# Remove .la files if present
find "${PREFIX}" -name '*.la' -delete 2>/dev/null || true
