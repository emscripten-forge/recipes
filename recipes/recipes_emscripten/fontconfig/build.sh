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
    --prefix=$PREFIX

emmake make RUN_FC_CACHE_TEST=false install
