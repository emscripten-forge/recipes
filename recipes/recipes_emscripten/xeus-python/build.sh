mkdir build
cd build

# remove all the fake pythons
rm -f $PREFIX/bin/python*


export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

if [[ $target_platform == "emscripten-wasm32" ]]; then
    export USE_WASM=ON
else
    export USE_WASM=OFF
fi

PYTHON_LIBRARIES="$PREFIX/lib/libbz2.a;\
$PREFIX/lib/libz.a;\
$PREFIX/lib/libsqlite3.a;\
$PREFIX/lib/libffi.a;\
$PREFIX/lib/libzstd.a;\
$PREFIX/lib/libssl.a;\
$PREFIX/lib/libcrypto.a;\
$PREFIX/lib/liblzma.a;\
$PREFIX/lib/libpython$PY_VER.a"

# Configure step
cmake ${CMAKE_ARGS} ..                                \
    -GNinja                                           \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DXPYT_EMSCRIPTEN_WASM_BUILD=$USE_WASM            \
    -DPYTHON_LIBRARIES="$PYTHON_LIBRARIES"

# Build step
ninja

ninja install

# remove raw-kernel
rm -rf $PREFIX/share/jupyter/kernels/xpython-raw/

