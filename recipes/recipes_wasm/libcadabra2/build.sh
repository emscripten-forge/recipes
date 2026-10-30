#!/usr/bin/env bash
set -euxo pipefail

mkdir -p build-lib
cd build-lib

# gmpxx.h / boost headers from the host prefix (c++lib/ only adds include
# paths for Python)
export CXXFLAGS="${CXXFLAGS:-} -I${PREFIX}/include"

# C++ library build of cadabra2 (c++lib/): libcadabra2++_static.a + headers.
emcmake cmake .. ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DBUILD_AS_CPP_LIBRARY=ON \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
    -DPython_EXECUTABLE="${PYTHON}" \
    -DPython_INCLUDE_DIR="${PREFIX}/include/python${PY_VER}" \
    -DPython_LIBRARY="${PREFIX}/lib/libpython${PY_VER}.a" \
    -DGMP_LIB="${PREFIX}/lib/libgmp.a" \
    -DGMPXX_LIB="${PREFIX}/lib/libgmpxx.a"

emmake make -j"${CPU_COUNT:-2}" cadabra2++ cadabra2++_static
emmake make install

# static library package: drop the shared libcadabra2++ (the install rule
# needs it to have been built)
rm -f "${PREFIX}/lib/libcadabra2++.so"
