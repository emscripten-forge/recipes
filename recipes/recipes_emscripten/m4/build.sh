# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* build-aux/

./configure --prefix=${PREFIX} --host=${HOST}
make -j${CPU_COUNT}
make install