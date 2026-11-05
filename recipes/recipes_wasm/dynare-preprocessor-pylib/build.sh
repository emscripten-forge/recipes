#!/bin/bash
set -euxo pipefail

export BOOST_ROOT=$PREFIX
# Meson's Python dependency would otherwise pick up the native
# python-3.14.pc and compile against the host's Python headers. Restrict
# pkg-config to the host prefix and bypass its wrapper's system search path.
export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig"
PKG_CONFIG_BIN="$BUILD_PREFIX/bin/pkg-config.bin"
sed -i "s|^pkgconfig = .*|pkgconfig = '${PKG_CONFIG_BIN}'|" "$MESON_CROSS_PYTHON_FILE"
grep -q "pkgconfig = '${PKG_CONFIG_BIN}'" "$MESON_CROSS_PYTHON_FILE"


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
