#!/bin/bash
set -e

mkdir build
cd build

# Set compiler flags
export CFLAGS="$CFLAGS $EMCC_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EMCC_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

# Configure step
emcmake cmake ${CMAKE_ARGS} ..      \
    -GNinja                         \
    -DCMAKE_BUILD_TYPE=Release      \
    -DCMAKE_PREFIX_PATH=$PREFIX     \
    -DCMAKE_INSTALL_PREFIX=$PREFIX  \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_VERBOSE_MAKEFILE=ON     \
    -DCMAKE_INCLUDE_PATH="$PREFIX/include" \
    -DCMAKE_LIBRARY_PATH="$PREFIX/lib" \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
    -DCMAKE_C_FLAGS_RELEASE="$CFLAGS" \
    -DCMAKE_CXX_FLAGS_RELEASE="$CXXFLAGS" \
    -DCMAKE_MODULE_LINKER_FLAGS_RELEASE="$LDFLAGS" \
    -DCMAKE_SHARED_LINKER_FLAGS_RELEASE="$LDFLAGS" \
    -DZLIB_ROOT=$PREFIX             \
    -DBZIP2_ROOT=$PREFIX            \
    -DLIBLZMA_ROOT=$PREFIX          \
    -DOPENSSL_ROOT_DIR=$PREFIX      \
    -DMZ_ZLIB=ON                    \
    -DMZ_BZIP2=ON                   \
    -DMZ_LZMA=ON                    \
    -DMZ_ZSTD=ON                    \
    -DMZ_PPMD=ON                    \
    -DMZ_PKCRYPT=ON                 \
    -DMZ_WZAES=ON                   \
    -DMZ_OPENSSL=ON                 \
    -DMZ_ICONV=OFF                  \
    -DMZ_LIBBSD=OFF                 \
    -DMZ_LIBCOMP=OFF                \
    -DMZ_COMPAT=ON                  \
    -DMZ_BUILD_TESTS=OFF            \
    -DMZ_BUILD_UNIT_TESTS=OFF       \
    -DMZ_FETCH_LIBS=OFF             \
    -DMZ_FORCE_FETCH_LIBS=OFF

# Build step
emmake ninja -v -j${CPU_COUNT}

# Install step
ninja install
