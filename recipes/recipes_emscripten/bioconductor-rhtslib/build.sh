# remove all shared zlib instances
rm $PREFIX/lib/libz.so* || true



$R CMD INSTALL $R_ARGS  . --disable-libcurl