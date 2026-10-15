#!/bin/bash

set -eux

export CFLAGS="-fPIC"
export CXXFLAGS="-fPIC"
export LDFLAGS="-L$PREFIX/lib"

# Install r-hera
$R CMD INSTALL $R_ARGS hera

# Create build directory
mkdir -p build
cd build

# Set up the environment variables for cross-compiling to WASM
export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# if R_MAIN_MODULE_STATIC_LIBPYTHON == 1, then we need to link against the static libpython
if [[ "$R_MAIN_MODULE_STATIC_LIBPYTHON" == "1" ]]; then
    export CMAKE_ARGS="$CMAKE_ARGS -DXEUS_R_LINK_LIBPYTHON=ON"

    export PY_STATIC="$PREFIX/lib/python$PY_VER/static"
    if [[ ! -d "$PY_STATIC" ]]; then
        echo "Error: Python static libraries not found at $PY_STATIC" >&2
        exit 1
    fi

    rpy_libs=(
      $PREFIX/lib/libpython${PY_VER}.a
      $PREFIX/lib/libbz2.a
      $PREFIX/lib/libz.a
      $PREFIX/lib/libsqlite3.a
      $PREFIX/lib/libffi.a
      $PREFIX/lib/libzstd.a
      $PREFIX/lib/libssl.a
      $PREFIX/lib/libcrypto.a
      $PREFIX/lib/liblzma.a
      $PY_STATIC/libexpat.a
      $PY_STATIC/libmpdec.a
      $PY_STATIC/libHacl_Hash_BLAKE2.a
      $PY_STATIC/libHacl_Hash_MD5.a
      $PY_STATIC/libHacl_Hash_SHA1.a
      $PY_STATIC/libHacl_Hash_SHA2.a
      $PY_STATIC/libHacl_Hash_SHA3.a
    )
    export RPY_LIBS="${rpy_libs[*]}"
else
    export CMAKE_ARGS="$CMAKE_ARGS -DXEUS_R_LINK_LIBPYTHON=OFF"
fi

# Configure step with Emscripten's emcmake
emcmake cmake ${CMAKE_ARGS} -S .. -B .                     \
    -DCMAKE_BUILD_TYPE=Release                             \
    -DCMAKE_PREFIX_PATH=$PREFIX                            \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                         \
    -DXEUS_R_EMSCRIPTEN_WASM_BUILD=ON                      \
    -DCMAKE_VERBOSE_MAKEFILE=ON

# Build step with emmake
emmake make -j1

# Install step
emmake make install

cat $PREFIX/share/jupyter/kernels/xr/kernel.json
