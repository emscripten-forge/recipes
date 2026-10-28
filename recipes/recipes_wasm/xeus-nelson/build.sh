mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# Configure step
cmake ${CMAKE_ARGS} ..                                \
    -GNinja                                           \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DXEUS_NELSON_EMSCRIPTEN_WASM_BUILD=ON

# Build step
ninja

ninja install
