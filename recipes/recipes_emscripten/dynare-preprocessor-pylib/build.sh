#!/bin/bash

export BOOST_ROOT=$PREFIX

# cp $RECIPE_DIR/meson.build src/meson.build

flags="-w -fexperimental-library -Wno-enum-constexpr-conversion -s SIDE_MODULE=1 -s WASM_BIGINT -fexceptions -std=c++20"

meson setup --prefix=$PREFIX --bindir=$PREFIX/bin --libdir=$PREFIX/lib --includedir=$PREFIX/include \
    --buildtype=release build_preproc \
    -Dcpp_args="$flags"  \
    -Dcpp_link_args="$flags" \
    --cross-file=$RECIPE_DIR/wasm_32.ini -Dbuild_library=enabled

meson compile -C build_preproc
meson install -C build_preproc #--destdir="../

rm $PREFIX/bin/python
