#!/bin/bash
set -euxo pipefail

export BOOST_ROOT=$PREFIX


meson setup build_wasm \
    --prefix=$PREFIX \
    --libdir=$PREFIX/lib \
    --includedir=$PREFIX/include \
    --bindir=$PREFIX/bin \
    --buildtype=release \
    -Dbuild_cli=disabled \
    -Dbuild_library=enabled \
    -Dbuild_doc=false \
    -Dcpp_args="-fwasm-exceptions" \
    -Dcpp_link_args="-fwasm-exceptions" \
    --cross-file=$MESON_CROSS_PYTHON_FILE

meson compile -C build_wasm -v
meson install -C build_wasm
