#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* ./conftools

emconfigure ./configure --prefix=$PREFIX \
            --host=${HOST} \
            --build=${BUILD} \
            --enable-static \
            --disable-shared

make -j${CPU_COUNT} ${VERBOSE_AT}
if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
      make check
fi
make install