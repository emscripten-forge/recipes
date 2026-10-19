#!/bin/bash

mkdir build_libjpeg && cd  build_libjpeg

cmake ${CMAKE_ARGS} -D CMAKE_INSTALL_PREFIX=$PREFIX \
      -D CMAKE_INSTALL_LIBDIR="$PREFIX/lib" \
      -D CMAKE_BUILD_TYPE=Release \
      -D ENABLE_STATIC=1 \
      -D ENABLE_SHARED=0 \
      -D WITH_JPEG8=1 \
      -D REQUIRE_SIMD=0 \
      -D WITH_SIMD=0 \
      $SRC_DIR
      # -D CMAKE_ASM_NASM_COMPILER=yasm \

make -j$CPU_COUNT
if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
ctest
fi
make install -j$CPU_COUNT

# We can remove this when we start using the new conda-build.
find $PREFIX -name '*.la' -delete