emconfigure ./configure \
    LIBS="`pkg-config --libs-only-l cblas` -lm" \
    LDFLAGS="$LDFLAGS `pkg-config --libs-only-L cblas`" \
    CPPFLAGS="$CPPFLAGS `pkg-config --cflags-only-I cblas`" \
    CFLAGS="$CFLAGS -fPIC `pkg-config --cflags-only-other cblas`" \
    --disable-shared
emmake make -j${CPU_COUNT}
emmake make install
