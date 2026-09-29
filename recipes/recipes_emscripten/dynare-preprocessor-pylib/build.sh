#!/bin/bash
set -ex

export BOOST_ROOT=$PREFIX

# Generate Meson cross-file for emscripten
cat << 'EOF' > emscripten.meson.cross
[properties]
needs_exe_wrapper = true
skip_sanity_check = true

[host_machine]
system = 'emscripten'
cpu_family = 'wasm32'
cpu = 'wasm32'
endian = 'little'

[binaries]
c = 'emcc'
cpp = 'em++'
ar = 'emar'
ranlib = 'emranlib'
pkgconfig = 'pkg-config'
python = '$PYTHON'
EOF

sed -i "s|'\$PYTHON'|'${PYTHON}'|g" emscripten.meson.cross

export CFLAGS="$CFLAGS -sWASM_BIGINT -sSIDE_MODULE=1 -fwasm-exceptions"
export CXXFLAGS="$CXXFLAGS -sWASM_BIGINT -sSIDE_MODULE=1 -fwasm-exceptions"
export LDFLAGS="$LDFLAGS -sWASM_BIGINT -sSIDE_MODULE=1 -fwasm-exceptions"

meson setup build_wasm \
    --prefix=$PREFIX \
    --libdir=$PREFIX/lib \
    --includedir=$PREFIX/include \
    --bindir=$PREFIX/bin \
    --buildtype=release \
    -Dbuild_cli=disabled \
    -Dbuild_library=enabled \
    -Dbuild_doc=false \
    -Dcpp_args="-fwasm-exceptions -sSIDE_MODULE=1 -sWASM_BIGINT" \
    -Dcpp_link_args="-fwasm-exceptions -sSIDE_MODULE=1 -sWASM_BIGINT" \
    --cross-file=$(pwd)/emscripten.meson.cross

meson compile -C build_wasm -v
meson install -C build_wasm
