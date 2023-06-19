# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

export CFLAGS="$CFLAGS -I$PREFIX/include -L$PREFIX/lib"
export CPPFLAGS="$CPPFLAGS -I$PREFIX/include"

emconfigure ./configure --prefix=$PREFIX \
            --with-zlib-prefix=$PREFIX

emmake make -j${CPU_COUNT} ${VERBOSE_AT}
emmake make install
