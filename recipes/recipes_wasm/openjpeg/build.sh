#!/bin/bash




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
        -DOPJ_USE_THREAD=OFF \
        -DBUILD_JPWL=OFF \
        -DBUILD_CODEC=OFF \
        $SRC_DIR

  make -j${CPU_COUNT} ${VERBOSE_CM}
  make install -j${CPU_COUNT}

popd