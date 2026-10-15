#!/bin/bash

cp $RECIPE_DIR/setup.py .

NUMPY_INCLUDE_DIR="$PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include/"
export CFLAGS="${CFLAGS} -fPIC -DHAVE_UINT32_T -I${NUMPY_INCLUDE_DIR}"
export CXXFLAGS="${CXXFLAGS} -fPIC -I${NUMPY_INCLUDE_DIR}"



# Specific variables for cross-compilation
if [[ "$target_platform" == "emscripten-wasm32" ]]; then

elif [[ "$target_platform" == "emscripten-wasm64" ]]; then
       export LDFLAGS="${LDFLAGS} -m64"
else
    echo "Unsupported target_platform: $target_platform"
    exit 1
fi


${PYTHON} -m pip install .

