#!/bin/bash

NUMPY_INCLUDE_DIRS="${PREFIX}/include/python${PY_VER}/site-packages/numpy/_core/include/"
export CFLAGS="${CFLAGS} -DHAVE_UINT32_T -I${NUMPY_INCLUDE_DIRS}"
export CXXFLAGS="${CXXFLAGS} -fPIC -I${NUMPY_INCLUDE_DIRS}"

mkdir -p build
cd build

emcmake cmake .. \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DPython_EXECUTABLE=${PYTHON} \
    -DNUMPY_INCLUDE_DIRS=${NUMPY_INCLUDE_DIRS} \
    -LAH \
    -DNLOPT_GUILE=OFF \
    -DNLOPT_MATLAB=OFF \
    -DNLOPT_OCTAVE=OFF \
    -DNLOPT_TESTS=OFF \
    -DCMAKE_VERBOSE_MAKEFILE=ON

emmake make VERBOSE=1 install

# emmake make install

# ${PYTHON} -m pip install .

