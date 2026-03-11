# !/bin/bash

# rm -f  $BUILD_PREFIX/bin/wasm-ld
# cp "${RECIPE_DIR}/wasm-ld-wrapper.sh" "$BUILD_PREFIX/bin/wasm-ld"
# chmod +x "$BUILD_PREFIX/bin/wasm-ld"



export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"

emconfigure ./configure \
    --host=wasm32-unknown-emscripten \
    --prefix=$PREFIX \
    --enable-hdri=yes \
    --with-quantum-depth=16 \
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