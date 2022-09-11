mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX


# Configure step
emcmake cmake ${CMAKE_ARGS} ..                        \
    -GNinja                                           \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DLibSolv_INCLUDE_DIRS=$PREFIX/include/libsolv    \
    -DLIBSOLV_LIBRARY=$PREFIX/lib/libsolv.a           \
    -DLIBSOLV_EXT_LIBRARY=$PREFIX/lib/libsolvext.a    \
    -DPYTHON_MODULE_INSTALL_DIR="$PREFIX/lib/python3.10/site-packages" \
    -DBUILD_DOCS=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_PYTHON=ON

# Build step
ninja



ninja install
