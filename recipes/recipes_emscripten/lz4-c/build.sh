#!/bin/bash
set -ex

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

# Build
emmake make PREFIX=${PREFIX} CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" HAVE_MULTITHREAD=0 VERBOSE=1

# Install
emmake make install PREFIX=${PREFIX}

# Install CMake config file
mkdir -p ${PREFIX}/lib/cmake/lz4
sed "s/@VERSION@/${PKG_VERSION}/g" ${RECIPE_DIR}/lz4Config.cmake > ${PREFIX}/lib/cmake/lz4/lz4Config.cmake
