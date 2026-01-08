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
    -DXEUS_LUA_EMSCRIPTEN_WASM_BUILD=ON               \
    -DXLUA_WITH_XWIDGETS=ON                           \
    -DXLUA_USE_SHARED_XWIDGETS=OFF                    \
    -DXLUA_WITH_XCANVAS=ON                            \
    -DXLUA_USE_SHARED_XCANVAS=OFF                     \
    -DLUA_INCLUDE_DIR=$PREFIX/include                 \
    -DLUA_LIBRARY=$PREFIX/lib/liblua.a

# Build step
ninja

ninja install
