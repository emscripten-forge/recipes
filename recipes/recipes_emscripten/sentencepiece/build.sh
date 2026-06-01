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
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DSPM_ENABLE_SHARED=OFF \
    -DSPM_BUILD_TEST=OFF \
    -DSPM_ENABLE_TCMALLOC=OFF \
    -DSPM_ABSL_PROVIDER=package \
    -DSPM_PROTOBUF_PROVIDER=internal \
    -DSPM_ENABLE_NFKC_COMPILE=OFF \
    ..

# Build only the static library (CLI tools fail to link due to duplicate
# abseil symbols between internal protobuf-lite and system libabseil)
ninja sentencepiece-static

# Install library and headers manually
mkdir -p "${PREFIX}/lib"
mkdir -p "${PREFIX}/include"
cp src/libsentencepiece.a "${PREFIX}/lib/"
cp ../src/sentencepiece_processor.h "${PREFIX}/include/"
cp ../src/sentencepiece_trainer.h "${PREFIX}/include/"

# Remove .la files if any
find "${PREFIX}" -name '*.la' -delete 2>/dev/null || true

# Install CMake config files
mkdir -p "${PREFIX}/lib/cmake/sentencepiece"

cp "${RECIPE_DIR}/sentencepieceConfigVersion.cmake" "${PREFIX}/lib/cmake/sentencepiece/"
sed -i "s/@PKG_VERSION@/${PKG_VERSION}/" "${PREFIX}/lib/cmake/sentencepiece/sentencepieceConfigVersion.cmake"
cp "${RECIPE_DIR}/sentencepieceConfig.cmake" "${PREFIX}/lib/cmake/sentencepiece/"
cp "${RECIPE_DIR}/sentencepieceTargets.cmake" "${PREFIX}/lib/cmake/sentencepiece/"
