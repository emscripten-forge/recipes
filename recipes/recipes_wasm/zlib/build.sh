mkdir build
cd build

# Set compiler flags
export CFLAGS="$CFLAGS $EMCC_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EMCC_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

# Configure step
emcmake cmake ${CMAKE_ARGS} ..      \
    -GNinja                         \
    -DCMAKE_BUILD_TYPE=Release      \
    -DCMAKE_PREFIX_PATH=$PREFIX     \
    -DCMAKE_INSTALL_PREFIX=$PREFIX  \
    -DZLIB_BUILD_EXAMPLES=OFF       \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_VERBOSE_MAKEFILE=ON     \
    -DCMAKE_C_FLAGS_RELEASE="$CFLAGS" \
    -DCMAKE_CXX_FLAGS_RELEASE="$CXXFLAGS" \
    -DCMAKE_MODULE_LINKER_FLAGS_RELEASE="$LDFLAGS" \
    -DCMAKE_PROJECT_INCLUDE=$RECIPE_DIR/overwriteProp.cmake

# Build step
emmake ninja -v

# Install step
ninja install

# Install CMake config file
mkdir -p $PREFIX/lib/cmake/zlib
sed "s|@ZLIB_VERSION@|$PKG_VERSION|g" $RECIPE_DIR/zlibConfig.cmake > $PREFIX/lib/cmake/zlib/zlibConfig.cmake
