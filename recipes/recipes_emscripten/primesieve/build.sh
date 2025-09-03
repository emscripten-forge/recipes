mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..                    \
    -GNinja                               \
    -DCMAKE_PREFIX_PATH:PATH=${PREFIX}    \
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON  \
    -DCMAKE_BUILD_TYPE=Release            \
    -DBUILD_SHARED_LIBS=OFF               \
    -DBUILD_PRIMESIEVE=OFF                \
    -DBUILD_TESTS=OFF

ninja install