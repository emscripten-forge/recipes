#!/bin/bash

set -ex

exception_flags="-fwasm-exceptions -sWASM_LEGACY_EXCEPTIONS=0 -sSUPPORT_LONGJMP=wasm"

export CFLAGS="${CFLAGS} ${exception_flags}"
export CXXFLAGS="${CXXFLAGS} ${exception_flags}"
export LDFLAGS="${LDFLAGS} ${exception_flags}"

meson_setup_args=(
    -Dtests=disabled
    -Dtools=disabled
    -Dc_args="${exception_flags}"
    -Dc_link_args="${exception_flags}"
)

meson setup builddir \
    "${meson_setup_args[@]}" \
    --prefix=$PREFIX \
    --buildtype=release \
    --prefer-static \
    --default-library=static \
    --cross-file=$MESON_CROSS_FILE

meson install -C builddir
