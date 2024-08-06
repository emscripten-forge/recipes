echo "DIR" $(pwd)

mkdir -p build
cd build

export CMAKE_PREFIX_PATH=$PREFIX 
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX 

echo "CXX" $CXX
echo "CC" $CC

export CC=emcc
export CXX=em++


# cp $BUILD_PREFIX/share/gnuconfig/config.* .

# Configure step
emmake cmake ${CMAKE_ARGS} ..  \
    -DCMAKE_BUILD_TYPE=Release      \
    -DCMAKE_PREFIX_PATH=$PREFIX     \
    -DCMAKE_INSTALL_PREFIX=$PREFIX  \
    -DBUILD_RUNTIME_BROWSER=ON \
    -DBUILD_RUNTIME_NODE=OFF \
    -DLINK_LIBMPDEC=OFF \
    -DLINK_LIBEXPAT=OFF \
    -DWITH_NODE_TESTS=OFF \
    -DCMAKE_TOOLCHAIN_FILE=$EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake \
    -DPY_VERSION=3.12 


# Build step
emmake make

emmake make install
