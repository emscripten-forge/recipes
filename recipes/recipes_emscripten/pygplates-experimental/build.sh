#!/usr/bin/env bash
set -euo pipefail

emscripten_root=$(em-config EMSCRIPTEN_ROOT)
toolchain_path="${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"

PY_VER=$(${BUILD_PREFIX}/bin/python -c "import sys; print('{}.{}'.format(*sys.version_info[:2]))")
PY_VER_MAJOR=${PY_VER%.*}
PY_VER_MINOR=${PY_VER#*.}

# Toolchain + find_package plumbing goes in CMAKE_ARGS (env-level).
# CMAKE_FIND_ROOT_PATH_MODE_* = BOTH opens find_package() to look outside the
# emscripten sysroot into the conda host prefix (ZLIB, CGAL, GDAL, PROJ, Qt6).
export CMAKE_ARGS="${CMAKE_ARGS:-} \
  -DCMAKE_TOOLCHAIN_FILE=${toolchain_path} \
  -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
  -DCMAKE_PREFIX_PATH=${PREFIX} \
  -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
  -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
  -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
  -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=BOTH"

# Bypass cross-python's ${PYTHON} wrapper: it hardcodes
# os.environ['_PYTHON_SYSCONFIGDATA_NAME']=...emscripten... at import time, and
# that wasm sysconfig contamination reaches CMake's FindPython3 probe.
# GPLATES_SKIP_FIND_PYTHON3 (recipe patch 0001) bypasses the probe entirely;
# we supply every Python3_* variable it would derive, from -D flags below.
BUILD_PY="${BUILD_PREFIX}/venv/build/bin/python"

# FindBoost runs its own find_library and doesn't reliably honor pre-set
# Boost_<component>_LIBRARY hints. Fix by materializing correctly-named
# libraries in a shim directory and pointing BOOST_LIBRARYDIR there:
#   - Symlink every libboost_*.a from $PREFIX/lib (so filesystem, program_options,
#     system, etc. resolve).
#   - Rename libboost_python${PY}-${PY}.a to plain libboost_python${PY}.a
#     (libboost-python's build tags with a double Python version suffix).
#   - Provide an empty libboost_thread.a stub, since emscripten-forge's
#     boost-cpp doesn't build boost::thread (no wasm threads). Symbol-level
#     uses will surface as link errors and can be handled with a follow-up
#     patch if pygplates goes beyond boost::thread's header-only bits.
BOOST_SHIM="${SRC_DIR}/wasm_boost_shim"
mkdir -p "${BOOST_SHIM}"
for lib in "${PREFIX}"/lib/libboost_*.a; do
  ln -sf "${lib}" "${BOOST_SHIM}/$(basename "${lib}")"
done
ln -sf "${PREFIX}/lib/libboost_python${PY_VER_MAJOR}${PY_VER_MINOR}-${PY_VER_MAJOR}${PY_VER_MINOR}.a" \
       "${BOOST_SHIM}/libboost_python${PY_VER_MAJOR}${PY_VER_MINOR}.a"
emar rcs "${BOOST_SHIM}/libboost_thread.a"
emar rcs "${BOOST_SHIM}/libboost_atomic.a"

env -u _PYTHON_SYSCONFIGDATA_NAME "${BUILD_PY}" -m pip install . \
  --prefix="${PREFIX}" --no-deps --no-build-isolation -vv \
  -Ccmake.define.EMSCRIPTEN=1 \
  -Ccmake.define.GPLATES_BUILD_GPLATES=FALSE \
  -Ccmake.define.GPLATES_INSTALL_STANDALONE_SHARED_LIBRARY_DEPENDENCIES=FALSE \
  -Ccmake.define.GPLATES_SKIP_FIND_PYTHON3=TRUE \
  -Ccmake.define.Boost_ROOT="${PREFIX}" \
  -Ccmake.define.Boost_NO_BOOST_CMAKE=TRUE \
  -Ccmake.define.Boost_NO_SYSTEM_PATHS=TRUE \
  -Ccmake.define.CMAKE_POLICY_DEFAULT_CMP0167=OLD \
  -Ccmake.define.QT_HOST_PATH="${BUILD_PREFIX}" \
  -Ccmake.define.BOOST_LIBRARYDIR="${BOOST_SHIM}" \
  -Ccmake.define.Boost_LIBRARY_DIRS="${BOOST_SHIM}" \
  -Ccmake.define.Boost_LIBRARY_DIR_RELEASE="${BOOST_SHIM}" \
  -Ccmake.define.BOOST_INCLUDEDIR="${PREFIX}/include" \
  -Ccmake.define.Python3_EXECUTABLE="${BUILD_PY}" \
  -Ccmake.define.Python3_INCLUDE_DIR="${PREFIX}/include/python${PY_VER}" \
  -Ccmake.define.Python3_LIBRARY="${PREFIX}/lib/libpython${PY_VER}.a" \
  -Ccmake.define.Python3_VERSION_MAJOR="${PY_VER_MAJOR}" \
  -Ccmake.define.Python3_VERSION_MINOR="${PY_VER_MINOR}" \
  -Ccmake.define.Python3_STDLIB="${PREFIX}/lib/python${PY_VER}" \
  -Ccmake.define.Python3_NumPy_INCLUDE_DIR="${BUILD_PREFIX}/lib/python${PY_VER}/site-packages/numpy/_core/include"
