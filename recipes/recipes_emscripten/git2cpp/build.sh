export CONFIG_CXXFLAGS="\
    -Os \
    -I$BUILD_PREFIX/include \
    "
export CONFIG_LDFLAGS="\
    -Os \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,getEnvStrings,TTY \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    "

export CXXFLAGS="$CXXFLAGS $CONFIG_CXXFLAGS"
export LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS"

emcmake cmake \
    -Bbuild \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -Dlibgit2_DIR=$PREFIX/lib/cmake/libgit2

cd build
emmake make -j$CPU_COUNT

mkdir -p $PREFIX/bin
cp git2cpp.{js,wasm} $PREFIX/bin/
