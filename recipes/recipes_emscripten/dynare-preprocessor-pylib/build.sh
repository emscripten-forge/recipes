#!/bin/bash

export BOOST_ROOT=$PREFIX

cp $RECIPE_DIR/meson.build src/meson.build

meson setup --prefix=$PREFIX --bindir=$PREFIX/bin --libdir=$PREFIX/lib --includedir=$PREFIX/include \
    --buildtype=release build_preproc \
    -Dcpp_args="-w  -Wno-enum-constexpr-conversion -I${PREFIX}/include/pybind11 -sSIDE_MODULE=1 -s WASM_BIGINT"  \
    -Dcpp_link_args="-w  -Wno-enum-constexpr-conversion -I${PREFIX}/include/pybind11 -sSIDE_MODULE=1 -s WASM_BIGINT" \
    --cross-file=$RECIPE_DIR/wasm_32.ini

meson compile -C build_preproc
meson install -C build_preproc #--destdir="../

rm $PREFIX/bin/python
