#!/bin/bash

declare -a CMAKE_PLATFORM_FLAGS
if [[ ${target_platform} == osx-64 ]]; then
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_OSX_SYSROOT="${CONDA_BUILD_SYSROOT}")
fi

mkdir build || true
pushd build

  cmake -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_STATIC_LIBS=ON \
        -DTIFF_LIBRARY=$PREFIX/lib/libtiff.a \
        -DTIFF_INCLUDE_DIR=$PREFIX/include \
        -DPNG_LIBRARY_RELEASE=$PREFIX/lib/libpng.a \
        -DPNG_PNG_INCLUDE_DIR=$PREFIX/include \
        -DZLIB_LIBRARY=$PREFIX/lib/libz.a \
        -DZLIB_INCLUDE_DIR=$PREFIX/include \
        -DBUILD_JPWL=OFF \
        -DBUILD_CODEC=OFF \
        "${CMAKE_PLATFORM_FLAGS[@]}" \
        $SRC_DIR

  make -j${CPU_COUNT} ${VERBOSE_CM}
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  ctest
fi
  make install -j${CPU_COUNT}

popd