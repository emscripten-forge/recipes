#!/bin/bash
set -ex

export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "\.cargo/bin" | grep -v "\.rustup" | tr '\n' ':' | sed 's/:$//')

EMCC=$(which emcc)
export EMSDK="${EMSCRIPTEN_FORGE_EMSDK_DIR}"
export PATH="${EMSDK}/upstream/bin:${PATH}"
EMSCRIPTEN_SYSTEM="${EMSDK}/upstream/emscripten/system"

rustup target add wasm32-unknown-emscripten
export CC="${EMCC}"
export CXX="${EMCC}++"
export AR="$(which emar)"
export RANLIB="$(which emranlib)"

echo "Checking for webgpu.h..."
ls -la ffi/webgpu-headers/webgpu.h

# bindgen include paths
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

# Emscripten side modules contain Rust-mangled exports, which are valid Wasm
# names but not JavaScript identifiers.  Do not validate those names as JS.
sed -i 's/if not n.isidentifier():/if not n.isidentifier() and not settings.SIDE_MODULE:/' \
  "${EMSDK}/upstream/emscripten/tools/emscripten.py"

# Cargo only forwards linker arguments from RUSTFLAGS.
export RUSTFLAGS="${RUSTFLAGS:-} -C link-arg=-sSIDE_MODULE=2"

mkdir -p .cargo
cat > .cargo/config.toml << 'EOF'
[target.wasm32-unknown-emscripten]
linker = "emcc"
EOF

# Patch Cargo.toml for Send/Sync on wasm
sed -i '/^\[features\]/a fragile-send-sync-non-atomic-wasm = ["wgc/fragile-send-sync-non-atomic-wasm", "hal/fragile-send-sync-non-atomic-wasm"]' Cargo.toml

cargo build --release \
  --target wasm32-unknown-emscripten \
  --no-default-features \
  --features wgsl,gles,fragile-send-sync-non-atomic-wasm

# Install
mkdir -p ${PREFIX}/lib ${PREFIX}/include/wgpu-native
cp target/wasm32-unknown-emscripten/release/libwgpu_native.so ${PREFIX}/lib/ 2>/dev/null || \
  cp target/wasm32-unknown-emscripten/release/wgpu_native.wasm ${PREFIX}/lib/libwgpu_native.wasm

cp ffi/webgpu-headers/webgpu.h ${PREFIX}/include/wgpu-native/
cp ffi/wgpu.h ${PREFIX}/include/wgpu-native/

echo "Build complete"
ls -la ${PREFIX}/lib/
