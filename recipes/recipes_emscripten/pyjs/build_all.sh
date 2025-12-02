echo "DIR" $(pwd)

mkdir -p build
cd build

# print all arguments passed to the script
echo "Arguments:" $@
# print first argument
echo "First argument:" $1

WHICH_PART=$1

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
    -DLINK_LIBLZMA=ON \
    -DWITH_NODE_TESTS=OFF \
    -DZLIB_INCLUDE_DIR=$PREFIX/include \
    -DZLIB_LIBRARY=$PREFIX/lib/libz.a  \
    -DCMAKE_TOOLCHAIN_FILE=$EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake


# Build step
emmake make
emmake make install


# if WHICH_PART is RT, then we delete a lot of unneeded files to keep the package small
if [ "$WHICH_PART" == "RT" ]; then
    echo "Cleaning up unneeded files for RT build"
    rm $PREFIX/lib/libpyjs.a
    rm -rf $PREFIX/lib/cmake
    rm -rf $PREFIX/lib_js
    rm -rf $PREFIX/include
fi