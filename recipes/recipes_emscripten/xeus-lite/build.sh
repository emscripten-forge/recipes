
mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DXSQL_BUILD_XSQLITE_EXECUTABLE=OFF \
    -DCMAKE_FIND_DEBUG_MODE=OFF \

# Build step
ninja install
