export LDFLAGS="${LDFLAGS} -sUSE_FREETYPE=1 -sUSE_PTHREADS=0"
export PTHREAD_CFLAGS=" "

# delete this file (is excluded in webr)
rm ./src/fcobjshash.h

mkdir build && cd build

emconfigure ../configure \
    ac_cv_func_fstatfs=no \
    ac_cv_func_link=no \
    --enable-shared=no \
    --enable-static=yes \
    --enable-expat \
    --prefix=$PREFIX \
    UUID_LIBS=$BUILD_PREFIX/lib/libuuid.a

emmake make RUN_FC_CACHE_TEST=false install

# Copy .wasm $PREFIX/bin/ files also
cp fc-cache/fc-cache.wasm $PREFIX/bin/
cp fc-cat/fc-cat.wasm $PREFIX/bin/
cp fc-list/fc-list.wasm $PREFIX/bin/
cp fc-match/fc-match.wasm $PREFIX/bin/
cp fc-pattern/fc-pattern.wasm $PREFIX/bin/
cp fc-query/fc-query.wasm $PREFIX/bin/
cp fc-scan/fc-scan.wasm $PREFIX/bin/
cp fc-validate/fc-validate.wasm $PREFIX/bin/
