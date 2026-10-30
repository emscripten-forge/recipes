set -ex

export CFLAGS="$CFLAGS -fPIC"
export LDFLAGS="$LDFLAGS  -fPIC"
export CXXFLAGS="$CXXFLAGS -fPIC"

# zlib, libjpeg, libpng and sqlite come from the host env as static libs
# (sqlite is our own build since we need to enable column metadata)

sed -i.bak 's|check_function_exists(fseek64 HAVE_FSEEK64)|set(HAVE_FSEEK64 FALSE)|' cmake/helpers/configure.cmake
sed -i.bak 's|check_function_exists(ftell64 HAVE_FTELL64)|set(HAVE_FTELL64 FALSE)|' cmake/helpers/configure.cmake
rm cmake/helpers/configure.cmake.bak


mkdir -p build
cd build && emcmake cmake .. \
-DCMAKE_INSTALL_PREFIX=$PREFIX \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=False \
-DBUILD_APPS=OFF \
-DCMAKE_C_FLAGS="-fPIC -Wno-deprecated-declarations -Wno-single-bit-bitfield-constant-conversion" \
-DCMAKE_CXX_FLAGS="-fPIC  -Wno-deprecated-declarations -Wno-single-bit-bitfield-constant-conversion" \
-DCMAKE_SHARED_LINKER_FLAGS="-sWASM_BIGINT" \
-DGDAL_USE_EXTERNAL_LIBS=OFF \
-DGDAL_USE_INTERNAL_LIBS=OFF \
-DGDAL_USE_CPL_MULTIPROC_PTHREAD=OFF \
\
-DPROJ_INCLUDE_DIR=$PREFIX/include \
-DPROJ_LIBRARY=$PREFIX/lib/libproj.a \
\
-DGDAL_USE_ICONV=ON \
-DIconv_INCLUDE_DIR=$PREFIX/include \
-DIconv_LIBRARY=$PREFIX/lib/libiconv.a \
\
-DGDAL_USE_TIFF=ON \
-DTIFF_INCLUDE_DIR=$PREFIX/include \
-DTIFF_LIBRARY=$PREFIX/lib/libtiff.a \
\
-DGDAL_USE_GEOS=ON \
-DGEOS_INCLUDE_DIR=$PREFIX/include \
-DGEOS_LIBRARY=$PREFIX/lib/libgeos_c.a \
\
-DGDAL_USE_ZLIB=ON \
-DZLIB_INCLUDE_DIR=$PREFIX/include \
-DZLIB_LIBRARY=$PREFIX/lib/libz.a \
\
-DGDAL_USE_PNG=ON \
-DPNG_PNG_INCLUDE_DIR=$PREFIX/include \
-DPNG_LIBRARY_RELEASE=$PREFIX/lib/libpng.a \
\
-DGDAL_USE_JPEG=ON \
-DJPEG_INCLUDE_DIR=$PREFIX/include \
-DJPEG_LIBRARY_RELEASE=$PREFIX/lib/libjpeg.a \
\
-DGDAL_USE_SQLITE3=ON \
-DSQLite3_INCLUDE_DIR=$PREFIX/include \
-DSQLite3_LIBRARY=$PREFIX/lib/libsqlite3.a \
-DACCEPT_MISSING_SQLITE3_MUTEX_ALLOC=ON \
-DACCEPT_MISSING_SQLITE3_RTREE:BOOL=ON \
\
-DGDAL_USE_GEOTIFF_INTERNAL=ON \
-DGDAL_USE_QHULL_INTERNAL=ON \
-DGDAL_USE_LERC_INTERNAL=ON \
-DGDAL_USE_JSONC_INTERNAL=ON \
-DGDAL_USE_PCRE2=OFF \
-DBUILD_TESTING=OFF \
-DBUILD_PYTHON_BINDINGS=OFF \
-DCMAKE_VERBOSE_MAKEFILE=OFF

emmake make -j 8
emmake make install

# GDAL installs bash-completion scripts under share/bash-completion/completions/
# with a `.py` extension (they are actually shell scripts). rattler-build's
# Python bytecode post-processing tries to compile them and emits parser
# warnings. bash-completion is useless in a WebAssembly target anyway.
rm -rf "$PREFIX/share/bash-completion"
