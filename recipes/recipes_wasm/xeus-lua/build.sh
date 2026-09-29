mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX


export LDFLAGS="-L$PREFIX/lib"

# Configure step
emcmake cmake $CMAKE_ARGS ..                          \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DXEUS_LUA_EMSCRIPTEN_WASM_BUILD=ON               \
    -DXLUA_WITH_XWIDGETS=ON                           \
    -DXLUA_WITH_XCANVAS=ON                            \
    -DLUA_FOUND=TRUE                                  \
    -DLUA_INCLUDE_DIR=$PREFIX/include                 \
    -DLUA_LIBRARY=$PREFIX/lib/liblua.a                \
    -DLUA_LIBRARIES=$PREFIX/lib/liblua.a            


make -j2 install