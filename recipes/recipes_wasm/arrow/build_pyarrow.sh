#!/bin/bash
set -euo pipefail

# pyarrow (scikit-build-core since Arrow 26) links the static Arrow C++
# libraries from the arrow-cpp-*-static packages into its extension modules.

# Setup emscripten toolchain for scikit-build-core
emscripten_root=$(em-config EMSCRIPTEN_ROOT)
toolchain_path="${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"

NUMPY_LIB="${PREFIX}/lib/python${PY_VER}/site-packages/numpy"
SYSCONFIG_NAME="_sysconfigdata__emscripten_${target_platform#emscripten-}-emscripten"

export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_TOOLCHAIN_FILE=${toolchain_path}"
# scikit-build-core strips on install by default; the host strip reorders the
# wasm sections of the side modules ("need the dylink section to be first"),
# hence -Cinstall.strip=false below
export CMAKE_BUILD_PARALLEL_LEVEL="${CPU_COUNT:-4}"

# python/CMakeLists.txt has an emscripten branch keyed on PYODIDE which
# takes the Python / NumPy locations from these variables
export PYODIDE=1
export PYTHONINCLUDE="${PREFIX}/include/python${PY_VER}"
export CPYTHONLIB="${PREFIX}/lib/libpython${PY_VER}.a"
export NUMPY_LIB
export SYSCONFIG_NAME
export _PYTHON_SYSCONFIGDATA_NAME="${SYSCONFIG_NAME}"
export ARROW_HOME="${PREFIX}"

# version comes from setuptools_scm, there is no git checkout here
export SETUPTOOLS_SCM_PRETEND_VERSION="${PKG_VERSION}"

export PYARROW_BUNDLE_ARROW_CPP=OFF
export PYARROW_BUNDLE_CYTHON_CPP=ON

cd "${SRC_DIR}/python"
"${PYTHON}" -m pip install . --no-deps --no-build-isolation -vvv \
  -Cbuild-dir="_build" \
  -Ccmake.define.CMAKE_PREFIX_PATH="${PREFIX}" \
  -Cinstall.strip=false \
  -Ccmake.define.CMAKE_PLATFORM_NO_VERSIONED_SONAME=TRUE \
  -Ccmake.define.Python3_NumPy_INCLUDE_DIR="${NUMPY_LIB}/_core/include" \
  -Ccmake.define.Arrow_DIR="${PREFIX}/lib/cmake/Arrow" \
  -Ccmake.define.ArrowCompute_DIR="${PREFIX}/lib/cmake/ArrowCompute" \
  -Ccmake.define.ArrowAcero_DIR="${PREFIX}/lib/cmake/ArrowAcero" \
  -Ccmake.define.ArrowDataset_DIR="${PREFIX}/lib/cmake/ArrowDataset" \
  -Ccmake.define.Parquet_DIR="${PREFIX}/lib/cmake/Parquet" \
  -Ccmake.define.PYARROW_WITH_ACERO=ON \
  -Ccmake.define.PYARROW_WITH_DATASET=ON \
  -Ccmake.define.PYARROW_WITH_PARQUET=ON \
  -Ccmake.define.PYARROW_WITH_PARQUET_ENCRYPTION=OFF

SP="${PREFIX}/lib/python${PY_VER}/site-packages"
# the extension modules depend on libarrow_python.so; put it on the
# loader's search path (as the 4x recipe did)
if [ -f "${SP}/pyarrow/libarrow_python.so" ]; then
    cp "${SP}/pyarrow/libarrow_python.so" "${PREFIX}/lib/libarrow_python.so"
fi

rm -rf "${SP}/pyarrow/tests"
rm -rf "${SP}/pyarrow/__pycache__/"
for disabled_file in _cuda.pxd _cuda.pyx _flight.pyx _gcsfs.pyx _hdfs.pyx; do
    rm -f "${SP}/pyarrow/${disabled_file}"
done
