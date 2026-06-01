#!/bin/bash
set -e

mkdir -p $PREFIX/include
cp *.h $PREFIX/include/

# Install CMake config files
mkdir -p $PREFIX/lib/cmake/stb
cp ${RECIPE_DIR}/stbConfig.cmake $PREFIX/lib/cmake/stb/
cp ${RECIPE_DIR}/stbTargets.cmake $PREFIX/lib/cmake/stb/
