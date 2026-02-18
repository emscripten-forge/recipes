#!/usr/bin/env bash

# Setup toolchain
emscripten_root=$(em-config EMSCRIPTEN_ROOT)
toolchain_path="${emscripten_root}/cmake/Modules/Platform/Emscripten.cmake"

# Setup build arguments
export CMAKE_BUILD_PARALLEL_LEVEL="${CPU_COUNT}"   
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_TOOLCHAIN_FILE=${toolchain_path} -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake"


export CMAKE_ARGS="${CMAKE_ARGS} \
    -DPython_INCLUDE_DIR=$PREFIX/include/python${PY_VER} \
    -DPYTHONLIBS_FOUND=TRUE \
    -DPYTHON_LIBRARIES=$PREFIX/lib/libpython${PY_VER}.a \
    -DPYTHON_INCLUDE_DIRS=$PREFIX/include/python${PY_VER} \
    -DPYTHON_SITE_PACKAGES=$PREFIX/lib/python${PY_VER}/site-packages \
    -DPYTHON_PREFIX=$PREFIX \
    -DPYTHON_MODULE_EXTENSION=.so \
    -DPYTHON_MODULE_PREFIX= \
    -DPYTHON_IS_DEBUG=0 \
    -DPYTHON_VERSION=${PY_VER}"

$PYTHON -m pip install . ${PIP_ARGS}
