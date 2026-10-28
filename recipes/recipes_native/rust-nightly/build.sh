#!/bin/bash
# Build rustc + cargo + std (host, wasm32-unknown-emscripten, wasm64-unknown-emscripten)
# from source and install them into $PREFIX.

set -euxo pipefail

export RUST_BACKTRACE=1

fetch_submodule() {
    git submodule update --init --depth 1 "$1"
}

fetch_submodule library/backtrace
fetch_submodule src/tools/cargo
fetch_submodule src/doc/book
fetch_submodule src/doc/reference
fetch_submodule src/tools/rustc-perf

SUBMODULE_SHA="$(git ls-tree HEAD src/llvm-project | awk '{print $3}')"
rm -rf src/llvm-project
git clone --filter=blob:none --no-checkout --depth 1 \
    https://github.com/rust-lang/llvm-project.git src/llvm-project
git -C src/llvm-project fetch --depth 1 origin "${SUBMODULE_SHA}"
git -C src/llvm-project sparse-checkout init --cone
git -C src/llvm-project sparse-checkout set libunwind
git -C src/llvm-project checkout "${SUBMODULE_SHA}"

unset EM_FORGE_OPTFLAGS EM_FORGE_DBGFLAGS EM_FORGE_LDFLAGS_BASE \
      EM_FORGE_CFLAGS_BASE EM_FORGE_SIDE_MODULE_LDFLAGS EM_FORGE_SIDE_MODULE_CFLAGS
unset CC CXX AR RANLIB

export LD_LIBRARY_PATH="${BUILD_PREFIX}/lib:${PREFIX}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

# Map the conda platform onto a Rust host triple (this is a native build).
case "${target_platform}" in
  linux-64)    host_triple="x86_64-unknown-linux-gnu" ;;
  linux-aarch64) host_triple="aarch64-unknown-linux-gnu" ;;
  osx-64)      host_triple="x86_64-apple-darwin" ;;
  osx-arm64)   host_triple="aarch64-apple-darwin" ;;
  *)
    echo "Unsupported target platform: ${target_platform}" >&2
    exit 1
    ;;
esac

sed -e "s|@HOST_TRIPLE@|${host_triple}|g" \
    -e "s|@CPU_COUNT@|${CPU_COUNT}|g" \
    -e "s|@BUILD_PREFIX@|${BUILD_PREFIX}|g" \
    -e "s|@PREFIX@|${PREFIX}|g" \
    "${RECIPE_DIR}/bootstrap.toml.in" > bootstrap.toml

if [[ "${target_platform}" == osx-* ]]; then
  export "CFLAGS_${host_triple//-/_}=-isystem ${PREFIX}/include"
  export OPENSSL_DIR="${PREFIX}"
fi

./x.py build --stage 2
./x.py install --stage 2 rustc cargo rust-src library/std

SYSROOT="$("${PREFIX}/bin/rustc" --print sysroot)"
GCC_LD_DIR="${SYSROOT}/lib/rustlib/${host_triple}/bin/gcc-ld"
mkdir -p "${GCC_LD_DIR}"
cp -a "${PREFIX}/bin/wasm-ld" "${GCC_LD_DIR}/wasm-ld"

for TASK in "activate" "deactivate"; do
    mkdir -p "${PREFIX}/etc/conda/${TASK}.d"
    cp "${RECIPE_DIR}/${TASK}.sh" "${PREFIX}/etc/conda/${TASK}.d/${TASK}_${PKG_NAME}.sh"
done
