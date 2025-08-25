#!/bin/bash

export BOOST_ROOT=$PREFIX

cp $RECIPE_DIR/meson.build src/meson.build

meson setup --prefix=$PREFIX --bindir=$PREFIX/bin --libdir=$PREFIX/lib --includedir=$PREFIX/include \
    --buildtype=release build_preproc \
    -Dcpp_args="-w -fexperimental-library -Wno-enum-constexpr-conversion -sSIDE_MODULE=1 -s WASM_BIGINT -fexceptions -s USE_PTHREADS=1 -std=c++20 -sPTHREAD_POOL_SIZE=2"  \
    -Dcpp_link_args="-w -fexperimental-library  -Wno-enum-constexpr-conversion -sSIDE_MODULE=1 -s WASM_BIGINT -fexceptions -s USE_PTHREADS=1 -std=c++20 -sPTHREAD_POOL_SIZE=2" \
    --cross-file=$RECIPE_DIR/wasm_32.ini

meson compile -C build_preproc
meson install -C build_preproc #--destdir="../

rm $PREFIX/bin/python
