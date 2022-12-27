mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

if [[ $target_platform == "emscripten-32" ]]; then
    export USE_WASM=ON
else
    export USE_WASM=OFF
fi

# Configure step
cmake ${CMAKE_ARGS} ..                                \
    -GNinja                                           \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DXEUS_LUA_EMSCRIPTEN_WASM_BUILD=$USE_WASM        \
    -DXLUA_WITH_XWIDGETS=ON                           \
    -DXLUA_USE_SHARED_XWIDGETS=OFF                    \
    -DXLUA_WITH_XCANVAS=ON                            \
    -DXLUA_USE_SHARED_XCANVAS=OFF                    

# Build step
ninja

ninja install
