export CONFIG_CXXFLAGS="\
    -Os \
    -I$BUILD_PREFIX/include \
    -Wno-deprecated-declarations \
    "

# stringToNewUTF8 and writeArrayToMemory are used by libgit2.
export CONFIG_LDFLAGS="\
    -Os \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,PROXYFS,TTY,stringToNewUTF8,writeArrayToMemory \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    --pre-js $RECIPE_DIR/pre.js \
    -sSTACK_SIZE=1MB \
    -lproxyfs.js \
    "

emcmake cmake \
    -Bbuild \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -Dlibgit2_DIR=$PREFIX/lib/cmake/libgit2 \
    -Dtermcolor_DIR=$BUILD_PREFIX/lib/cmake/termcolor \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS $CONFIG_CXXFLAGS" \
    -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS $CONFIG_LDFLAGS"

cd build
emmake make -j$CPU_COUNT

mkdir -p $PREFIX/bin
cp git2cpp.{js,wasm} $PREFIX/bin/
