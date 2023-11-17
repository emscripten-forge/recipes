CC_FOR_BUILD=emcc CPP_FOR_BUILD=emcc HOST_CC=emcc  emconfigure ./configure \
    CFLAGS="$CFLAGS -fPIC" \
    --prefix=${PREFIX}  \
    --disable-assembly  \
    --enable-cxx \
    --host=none \
    # --enable-fat

emmake make -j${CPU_COUNT}
emmake make install
