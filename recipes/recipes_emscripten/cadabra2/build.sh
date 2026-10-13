#!/usr/bin/env bash
set -euxo pipefail

# Build only the `cadabra2` Python extension module, its pure-Python helpers
# (cadabra2_defaults.py, cdb_appdirs.py) and the `cdb` notebook packages.
# The command line REPL (cadabra2-cli), the notebook tools, the client/server
# and the GTK frontend are native programs which embed Python; in the browser
# Cadabra is used from the Python interpreter instead (see
# patches/0001-Add-options-to-build-only-the-Python-module.patch).

PY_SITE_REL="lib/python${PY_VER}/site-packages"

# whereami.c does not know about Emscripten; the /proc/self/exe code path
# compiles and fails gracefully at runtime (Cadabra only uses it to locate
# optional data files).
export CFLAGS="${CFLAGS} -DWAI_USE_PROC_SELF_EXE"
export CXXFLAGS="${CXXFLAGS:-} ${CFLAGS}"

# cmake/version.cmake asks git for the commit that is reported as the build
# id; keep it from picking up a surrounding (recipe) repository.
export GIT_CEILING_DIRECTORIES="$(dirname "${SRC_DIR}")"

mkdir -p build
cd build

# CMAKE_ARGS already selects the Emscripten toolchain. Do not go through
# `emcmake` (or the `cmake` shell function of the compiler activation, which
# calls it): emcmake runs under $PYTHON, the cross-python (crossenv) wrapper,
# and the nested cross-python which CMake then starts to query the target
# Python (SOABI, version) aborts with "Crossenv has leaked into another
# Python interpreter".
command cmake ${CMAKE_ARGS} .. \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PROJECT_INCLUDE="${RECIPE_DIR}/overwriteProp.cmake" \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF \
    -DCADABRA_PYTHON_MODULE_ONLY=ON \
    -DEMBED_COMPILED_PACKAGES=ON \
    -DENABLE_FRONTEND=OFF \
    -DENABLE_JUPYTER=OFF \
    -DENABLE_PY_JUPYTER=OFF \
    -DENABLE_MATHEMATICA=OFF \
    -DBUILD_TESTS=OFF \
    -DPython_EXECUTABLE="${PYTHON}" \
    -DPython_INCLUDE_DIR="${PREFIX}/include/python${PY_VER}" \
    -DPython_LIBRARY="${PREFIX}/lib/libpython${PY_VER}.a" \
    -DPYTHON_SITE_PATH="${PY_SITE_REL}" \
    -DGMP_INCLUDE_DIRS="${PREFIX}/include" \
    -DGMP_LIBRARIES="${PREFIX}/lib/libgmp.a" \
    -DGMPXX_LIBRARIES="${PREFIX}/lib/libgmpxx.a"

ninja -j${CPU_COUNT}
ninja install

# Sanity check: the extension module must be a WebAssembly side module.
MODULE=$(ls "${PREFIX}/${PY_SITE_REL}"/cadabra2.cpython-*-wasm32-emscripten.so)
head -c 4 "${MODULE}" | od -An -c | grep -q 'a   s   m'
