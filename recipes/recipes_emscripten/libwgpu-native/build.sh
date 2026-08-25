#!/usr/bin/env bash
set -euo pipefail

EMSDK="${EMSCRIPTEN_FORGE_EMSDK_DIR}"
EMSCRIPTEN_SYSTEM="${EMSDK}/upstream/emscripten/system"

rustup target add wasm32-unknown-emscripten

BINDGEN_ARGS="--target=wasm32-unknown-emscripten \
  -I${EMSCRIPTEN_SYSTEM}/include \
  -I${EMSCRIPTEN_SYSTEM}/include/compat \
  -I${EMSCRIPTEN_SYSTEM}/include/libc \
  -I${EMSCRIPTEN_SYSTEM}/lib/libc/musl/include \
  -I${EMSCRIPTEN_SYSTEM}/lib/libc/musl/arch/emscripten \
  -Iffi/webgpu-headers \
  -I."
export BINDGEN_EXTRA_CLANG_ARGS="${BINDGEN_ARGS}"
export BINDGEN_EXTRA_CLANG_ARGS_wasm32_unknown_emscripten="${BINDGEN_ARGS}"

# Side modules export Rust-mangled symbols ($, <, >), which are valid wasm
# names but not JS identifiers. Skip that validation for side modules.
sed -i 's/if not n.isidentifier():/if not n.isidentifier() and not settings.SIDE_MODULE:/' \
  "${EMSDK}/upstream/emscripten/tools/emscripten.py"

# Cargo only forwards linker arguments from RUSTFLAGS.
export RUSTFLAGS="${RUSTFLAGS:+${RUSTFLAGS} }-C link-arg=-sSIDE_MODULE=2"

# wgpu-native v29.0.1.1 doesn't expose fragile-send-sync-non-atomic-wasm.
sed -i '/^\[features\]/a fragile-send-sync-non-atomic-wasm = ["wgc/fragile-send-sync-non-atomic-wasm", "hal/fragile-send-sync-non-atomic-wasm"]' Cargo.toml

cargo build --release \
  --target wasm32-unknown-emscripten \
  --no-default-features \
  --features wgsl,gles,fragile-send-sync-non-atomic-wasm

mkdir -p ${PREFIX}/lib ${PREFIX}/include/wgpu-native
cp target/wasm32-unknown-emscripten/release/wgpu_native.wasm ${PREFIX}/lib/libwgpu_native.wasm
cp ffi/webgpu-headers/webgpu.h ffi/wgpu.h ${PREFIX}/include/wgpu-native/
