export ac_cv_header_linux_version_h=yes

emconfigure ./configure       \
    --prefix=$PREFIX          \
    --disable-all-programs    \
    --enable-libuuid          \
    --disable-shared          \
    --enable-static

emmake make
emmake make install
