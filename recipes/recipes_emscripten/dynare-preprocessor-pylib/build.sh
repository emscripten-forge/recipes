#!/bin/bash

export BOOST_ROOT=$PREFIX

cp $RECIPE_DIR/meson.build src/meson.build

meson setup --prefix=$PREFIX --bindir=$PREFIX/bin --libdir=$PREFIX/lib --includedir=$PREFIX/include \
    --buildtype=release build_preproc \
    -Dcpp_args="-pthread -w  -Wno-enum-constexpr-conversion -I${PREFIX}/include/pybind11"  \
    -Dcpp_link_args="-pthread -w  -Wno-enum-constexpr-conversion -I${PREFIX}/include/pybind11" \
    --cross-file=$RECIPE_DIR/wasm_32.ini

meson compile -C build_preproc
meson install -C build_preproc #--destdir="../