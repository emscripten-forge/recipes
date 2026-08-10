# remove all shared zlib instances
rm $PREFIX/lib/libz.so* || true



echo "remove threading"

find . \( -name "*.h" -o -name "*.c" \) -type f \
    -exec sed -i.bak 's/#ifndef NO_THREADS/#ifdef ENABLE_THREADS/g' {} +

echo "remove libcurl"

sed -i.bak \
    's/if test "\$enable_libcurl" != no; then/if false; then/' \
    src/htslib-1.18/configure

echo "remove libcurl even more"

find . \( -name "*.h" -o -name "*.c" \) -type f \
    -exec sed -i.bak 's/#ifdef HAVE_LIBCURL/#ifdef WE_NEVER_HAVE_LIBCURL/g' {} +

cp $RECIPE_DIR/Makefile.Rhtslib src/htslib-1.18/Makefile.Rhtslib


echo 'remove linkage to libcurl src/Makevars'
#  PKG_LIBS+=-lcurl -lbz2 -llzma -lz
# we replace -lcurl with an empty string to avoid linking against libcurl, which is not supported in Emscripten


sed -i.bak 's/-lcurl//g' src/Makevars
sed -i.bak 's/-lcurl//g' R/zzz.R




$R CMD INSTALL $R_ARGS  .