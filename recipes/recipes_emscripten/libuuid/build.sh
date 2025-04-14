emconfigure ./configure --prefix=$PREFIX --disable-all-programs --enable-libuuid --disable-shared --enable-static

emmake make
emmake make install
