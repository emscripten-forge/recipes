emconfigure ./configure \
    LIBS="`pkg-config --libs-only-l openblas` -lm" \
    LDFLAGS="$LDFLAGS `pkg-config --libs-only-L openblas`" \
    CPPFLAGS="$CPPFLAGS `pkg-config --cflags-only-I openblas`" \
    CFLAGS="$CFLAGS -fPIC `pkg-config --cflags-only-other openblas`" \
    --prefix=${PREFIX} \
    --disable-shared
emmake make -j${CPU_COUNT}
emmake make install
