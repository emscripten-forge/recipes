mkdir build
cd build

# Configure step
emcmake cmake ${CMAKE_ARGS} ..              \
    -GNinja                         \
    -DCMAKE_PREFIX_PATH:PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=FALSE \
    -DFLATBUFFERS_BUILD_TESTS=OFF \
    -DFLATBUFFERS_BUILD_FLATC=ON \
    # -DCMAKE_EXE_LINKER_FLAGS="-s EXPORT_ES6=1 -s USE_ES6_IMPORT_META=1 -s STANDALONE_WASM=1" \

# Build step
emmake ninja install

# Copy wasm file also
cp ./flatc.wasm $PREFIX/bin/
