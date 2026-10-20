#!/usr/bin/env bash
set -ex

export CFLAGS="${CFLAGS:-} $EM_FORGE_SIDE_MODULE_CFLAGS"

# Compile library source files
for f in decode identify quirc version_db; do
    emcc -Ilib ${CFLAGS} -c lib/${f}.c -o ${f}.o
done

# Create static library
emar rcs libquirc.a decode.o identify.o quirc.o version_db.o

# Install
mkdir -p ${PREFIX}/lib ${PREFIX}/include
cp libquirc.a ${PREFIX}/lib/
cp lib/quirc.h ${PREFIX}/include/

# Install CMake config
mkdir -p ${PREFIX}/lib/cmake/quirc
sed "s|@VERSION@|${PKG_VERSION}|g" ${RECIPE_DIR}/quircConfig.cmake > ${PREFIX}/lib/cmake/quirc/quircConfig.cmake
