#!/bin/bash

mkdir -p build && cd build

# Force support for shared libraries
echo "set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)" > ${SRC_DIR}/SupportSharedLib.cmake

export LDFLAGS="$LDFLAGS -s SIDE_MODULE=1"

emcmake cmake ${CMAKE_ARGS} -GNinja \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX=${PREFIX} \
      -D CMAKE_INSTALL_LIBDIR=lib \
      -D BUILD_SHARED_LIBS=ON \
      -D BUILD_TESTING=OFF \
      -D BUILD_BENCHMARKS=OFF \
      -D BUILD_DOCUMENTATION=OFF \
      -D CMAKE_PROJECT_INCLUDE=SupportSharedLib.cmake \
      ${SRC_DIR}

ninja

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
    ctest --output-on-failure
fi

ninja install -j${CPU_COUNT}

# remove links
cp $(readlink -f $PREFIX/lib/libgeos_c.so) $PREFIX/lib/libgeos_c_tmp.so
mv $PREFIX/lib/libgeos_c_tmp.so $PREFIX/lib/libgeos_c.so

cp $(readlink -f $PREFIX/lib/libgeos.so) $PREFIX/lib/libgeos_tmp.so
mv $PREFIX/lib/libgeos_tmp.so $PREFIX/lib/libgeos.so
