mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

if [[ $target_platform == "emscripten-wasm32" ]]; then
    export USE_WASM=ON
else
    export USE_WASM=OFF
fi

ls $PREFIX/lib
echo "BUILDING"

# Configure step
emcmake cmake ${CMAKE_ARGS} -S .. -B .                \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DXEUS_CPP_EMSCRIPTEN_WASM_BUILD=$USE_WASM        \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON            \
    -DCMAKE_CXX_FLAGS="-Dwait4=__syscall_wait4"       \
    -DCMAKE_VERBOSE_MAKEFILE=ON

# Build step
EMCC_CFLAGS='-sERROR_ON_UNDEFINED_SYMBOLS=0' emmake make -j1

# Install step
emmake make install
