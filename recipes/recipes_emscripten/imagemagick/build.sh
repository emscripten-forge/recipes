# !/bin/bash

# rm -f  $BUILD_PREFIX/bin/wasm-ld
# cp "${RECIPE_DIR}/wasm-ld-wrapper.sh" "$BUILD_PREFIX/bin/wasm-ld"
# chmod +x "$BUILD_PREFIX/bin/wasm-ld"



export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"

export LIBPNG_CFLAGS="-I$PREFIX/include"
export LIBPNG_LIBS="-L$PREFIX/lib -lpng"

file $PREFIX/lib/libpng.a



mkdir -p "$PREFIX/lib/pkgconfig"

cat > "$PREFIX/lib/pkgconfig/libpng.pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libpng
Description: PNG reference library
Version: 1.6.55
Libs: -L\${libdir} -lpng
Cflags: -I\${includedir}
EOF

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"


pkg-config --libs libpng



emconfigure ./configure \
    --host=wasm32-unknown-emscripten \
    --prefix=$PREFIX \
    --with-quantum-depth=8 \
    --disable-hdri \
    --disable-docs \
    --disable-static \
    --disable-openmp \
    --with-bzlib=yes \
    --with-autotrace=no \
    --with-djvu=no \
    --with-dps=no \
    --with-fftw=no \
    --with-flif=no \
    --with-fpx=no \
    --with-fontconfig=no \
    --with-freetype=no \
    --with-gslib=no \
    --with-gvc=no \
    --with-heic=no \
    --with-jbig=no \
    --with-jpeg=yes \
    --with-lcms=no \
    --with-lqr=no \
    --with-ltdl=no \
    --with-lzma=no \
    --with-magick-plus-plus=yes \
    --with-openexr=no \
    --with-openjp2=no \
    --with-pango=no \
    --with-perl=no \
    --with-png=yes \
    --with-raqm=no \
    --with-raw=no \
    --with-rsvg=yes \
    --with-tiff=yes \
    --with-webp=yes \
    --with-wmf=no \
    --with-x=no \
    --with-xml=yes \
    --with-zlib=yes \
    --with-glib=no

emmake make install