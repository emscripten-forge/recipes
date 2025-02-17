# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* build-aux/

# ensure _OBSTACK_NO_ERROR_HANDLER is defined

# export CFLAGS="${CFLAGS} -D_OBSTACK_NO_ERROR_HANDLER"


./configure --prefix=${PREFIX} --host=${HOST}  ac_cv_have_decl_alarm=no gl_cv_func_sleep_works=yes
make -j${CPU_COUNT}
make install