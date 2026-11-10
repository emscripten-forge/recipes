#!/bin/bash

set -ex

export CFLAGS="${CFLAGS} -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS} -fwasm-exceptions"
export LDFLAGS="${LDFLAGS} -fwasm-exceptions"

meson_setup_args=(
    -Dtests=disabled
    -Dtools=disabled
    -Dc_args="-fwasm-exceptions"
    -Dc_link_args="-fwasm-exceptions"
)

meson setup builddir \
    "${meson_setup_args[@]}" \
    --prefix=$PREFIX \
    --buildtype=release \
    --prefer-static \
    --default-library=static \
    --cross-file=$MESON_CROSS_FILE

meson install -C builddir
