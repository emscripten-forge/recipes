set -ex

autoreconf -f
emconfigure ./configure \
    --prefix=${PREFIX} \
    --host=${HOST}  \
    ac_cv_have_decl_alarm=no \
    gl_cv_func_sleep_works=yes \
    MAKEINFO=true
emmake make -j${CPU_COUNT}
emmake make install

# Copy .wasm file
cp ./src/m4.wasm $PREFIX/bin/
