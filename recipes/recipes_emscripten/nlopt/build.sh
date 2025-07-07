#!/bin/bash
export CFLAGS="${CFLAGS} -DHAVE_UINT32_T"
export CXXFLAGS="${CXXFLAGS} -fPIC"

mkdir -p build
cd build

emcmake cmake .. \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -LAH \
    -DNLOPT_GUILE=OFF \
    -DNLOPT_MATLAB=OFF \
    -DNLOPT_OCTAVE=OFF \
    -DNLOPT_TESTS=OFF

emmake make install

# ${PYTHON} -m pip install .

