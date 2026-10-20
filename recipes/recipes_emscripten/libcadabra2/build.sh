#!/usr/bin/env bash
set -euxo pipefail

mkdir -p build-lib
cd build-lib

PY_VER=$(ls "${PREFIX}/include" | grep -E '^python3\.[0-9]+$' | head -n 1)
PY_LIB=$(find "${PREFIX}/lib" -name "lib${PY_VER}.*" -print -quit)

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=c++11" \

emcmake cmake .. \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DBUILD_AS_CPP_LIBRARY=ON \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
    -DPython_EXECUTABLE="${BUILD_PREFIX}/bin/python" \
    -DPython_INCLUDE_DIR="${PREFIX}/include/${PY_VER}" \
    -DPython_LIBRARY="${PY_LIB}" \
    -DGMP_LIB="${PREFIX}/lib/libgmp.a" \
    -DGMP_INCLUDE_DIR="${PREFIX}/include"

emmake make -j8 
emmake make install