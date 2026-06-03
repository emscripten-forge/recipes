# remove all shared zlib instances
rm $PREFIX/lib/libz.so* || true



# in src/htslib-1.18/hfile.c we want to replace #ifdef HAVE_LIBCURL with #if 0
# using sed
sed -i.bak 's/#ifdef HAVE_LIBCURL/#if 0/g' src/htslib-1.18/hfile.c
rm -f src/htslib-1.18/hfile.c.bak

$R CMD INSTALL $R_ARGS  . --disable-libcurl