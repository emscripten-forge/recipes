#!/bin/bash

# https://github.com/json-c/json-c/issues/406
export CPPFLAGS="${CPPFLAGS/-DNDEBUG/}"


mkdir build
cd build
emcmake cmake $CMAKE_ARGS \
    -DISABLE_BSYMBOLIC=ON \
    -DISABLE_THREAD_LOCAL_STORAGE=ON \
    -DISABLE_WERROR=ON \
    -DENABLE_RDRAND=OFF \
    -DENABLE_THREADING=OFF \
    -DOVERRIDE_GET_RANDOM_SEED=OFF \
    -DDISABLE_EXTRA_LIBS=ON \
    -DBUILD_APPS=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=$BUILD_SHARED_LIBS \
    -DBUILD_STATIC_LIBS=$BUILD_STATIC_LIBS \
    .. 

emmake make ${VERBOSE_AT}
emmake make install

# We can remove this when we start using the new conda-build.
find $PREFIX -name '*.la' -delete