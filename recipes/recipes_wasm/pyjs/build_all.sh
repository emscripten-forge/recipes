echo "DIR" $(pwd)

mkdir -p build
cd build

# print all arguments passed to the script
echo "Arguments:" $@
# print first argument
echo "First argument:" $1

WHICH_PART=$1


# Specific variables for cross-compilation
if [[ "$target_platform" == "emscripten-wasm32" ]]; then
    USE_WASM64=FALSE
elif [[ "$target_platform" == "emscripten-wasm64" ]]; then
    USE_WASM64=TRUE
else
    echo "Unsupported target_platform: $target_platform"
    exit 1
fi

export CMAKE_PREFIX_PATH=$PREFIX 
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX 
export CC=emcc
export CXX=em++


# detect python version 
PY_VER=$(
    basename -- "$PREFIX"/include/python* |
    sed 's/^python//'
)
echo "Detected Python version:" $PY_VER

# Configure step
emmake cmake ${CMAKE_ARGS} ..  \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
    -DBUILD_RUNTIME_BROWSER=ON \
    -DBUILD_RUNTIME_NODE=OFF \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DLINK_LIBLZMA=ON \
    -DPY_VERSION=$PY_VER \
    -DPYTHON_SITE_PACKAGES=$PREFIX/lib/python${PY_VER}/site-packages \
    -DPython_INCLUDE_DIRS=$PREFIX/include/python${PY_VER} \
    -DPython_LIBRARY=$PREFIX/lib/libpython${PY_VER}.a \
    -DPython_LIBRARIES=$PREFIX/lib/libpython${PY_VER}.a \
    -DPython_Interpreter_FOUND=TRUE \
    -DPython_EXECUTABLE=$BUILD_PREFIX/bin/python${PY_VER} \
    -DPYTHON_MODULE_EXTENSION=.so \
    -DPYTHON_MODULE_DEBUG_POSTFIX="" \
    -DPYTHON_MODULE_EXT_SUFFIX=.so \
    -DPython_FOUND=TRUE \
    -DWASM64=$USE_WASM64 \


emmake make
emmake make install