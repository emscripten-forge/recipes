#!/bin/bash

export BOOST_ROOT=$PREFIX

set -ex
export PKG_CONFIG=$(which pkg-config)
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"

flags="-w -fexperimental-library -Wno-enum-constexpr-conversion \
    -sSIDE_MODULE=1 -sWASM_BIGINT -fwasm-exceptions -std=c++20 \
    -I$PREFIX/include/python$PY_VER"

meson setup --prefix=$PREFIX --bindir=$PREFIX/bin --libdir=$PREFIX/lib --includedir=$PREFIX/include \
    --buildtype=release build_preproc \
    -Dcpp_args="$flags"  \
    -Dcpp_link_args="$flags" \
    --cross-file=$RECIPE_DIR/wasm_32.ini -Dbuild_library=enabled

meson compile -C build_preproc
meson install -C build_preproc #--destdir="../

rm $PREFIX/bin/python
