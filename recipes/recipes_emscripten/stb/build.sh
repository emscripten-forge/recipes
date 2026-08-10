#!/bin/bash
set -e

export CFLAGS="${CFLAGS} ${EM_FORGE_SIDE_MODULE_CFLAGS}"

# Install headers
mkdir -p $PREFIX/include
cp *.h $PREFIX/include/

# Build stb_vorbis as a static library
mkdir -p $PREFIX/lib
${CC} -c stb_vorbis.c -DSTB_VORBIS_IMPLEMENTATION ${CFLAGS} -o stb_vorbis.o
${AR} rcs $PREFIX/lib/libstb_vorbis.a stb_vorbis.o

# Install CMake config files
mkdir -p $PREFIX/lib/cmake/stb
cp ${RECIPE_DIR}/stbConfig.cmake $PREFIX/lib/cmake/stb/
cp ${RECIPE_DIR}/stbTargets.cmake $PREFIX/lib/cmake/stb/
