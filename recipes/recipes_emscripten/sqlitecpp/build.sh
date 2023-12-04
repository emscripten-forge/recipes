
mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DSQLITECPP_USE_STACK_PROTECTION=OFF \
    -DSQLITECPP_RUN_CPPLINT=OFF \
    -DSQLITECPP_RUN_CPPCHECK=OFF 

# Build step
ninja install
