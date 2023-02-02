mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

if [[ $target_platform == "emscripten-32" ]]; then
    export USE_WASM=ON
else
    export USE_WASM=OFF
fi

ls $PREFIX/lib
echo "BUILDING"

# Configure step
cmake ${CMAKE_ARGS} ..                                \
    -GNinja                                           \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DXEUS_NELSON_EMSCRIPTEN_WASM_BUILD=$USE_WASM     

# Build step
ninja

ninja install
