#!/bin/bash
set -euxo pipefail

# Native lean toolchain (must match the lean-toolchain file of xeus-lean).
# It runs `lake build` (Lean -> C) and provides the Init/Std/Lean .olean files.
# conda-forge only ships newer lean4 versions, so use the upstream release.
LEAN_VERSION=4.28.0
case "$(uname -s)-$(uname -m)" in
    Linux-x86_64)
        LEAN_ASSET=linux
        LEAN_SHA256=ceb3a3f844f7aebf63245e2b51c28d5b0ed38942c19f93cf3febd520302160bd ;;
    Darwin-arm64)
        LEAN_ASSET=darwin_aarch64
        LEAN_SHA256=61942f9d1907db918020154a517c87fb64841e48cebb0032fc0909df8d189a05 ;;
    *)
        echo "unsupported build platform"; exit 1 ;;
esac
python - "${LEAN_VERSION}" "${LEAN_ASSET}" "${LEAN_SHA256}" <<'EOF'
import hashlib, sys, urllib.request
version, asset, sha = sys.argv[1:]
url = f"https://github.com/leanprover/lean4/releases/download/v{version}/lean-{version}-{asset}.tar.zst"
data = urllib.request.urlopen(url).read()
assert hashlib.sha256(data).hexdigest() == sha, "sha256 mismatch"
open("lean.tar.zst", "wb").write(data)
EOF
mkdir -p _lean
zstd -dc lean.tar.zst | tar -x -C _lean --strip-components=1
rm lean.tar.zst
LEAN_TOOLCHAIN_DIR=${SRC_DIR}/_lean

# Lean -> C for the REPL; the generated .lake/build/ir/*.c are compiled to wasm by cmake.
# The lean toolchain ships its own clang, so keep it off PATH for the emscripten build.
PATH=${LEAN_TOOLCHAIN_DIR}/bin:${PATH} lake build REPL CommBus Display WasmRepl

emcmake cmake -S . -B wasm-build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_FIND_ROOT_PATH=${PREFIX} \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
    -DPython3_EXECUTABLE=${BUILD_PREFIX}/bin/python \
    -DLEAN_TOOLCHAIN_DIR=${LEAN_TOOLCHAIN_DIR} \
    -DLEAN4_VERSION=v${LEAN_VERSION} \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
    -DFETCHCONTENT_SOURCE_DIR_LEAN4=${SRC_DIR}/_deps/lean4

emmake make -C wasm-build -j${CPU_COUNT} xlean test_wasm_node

# smoke test: Lean REPL (stage0 libs + Init oleans) under node.
# test_wasm_node is linked with EXIT_RUNTIME=0, so check its output instead of the exit code.
node wasm-build/test_wasm_node.js 2>&1 | tee test_wasm_node.log
grep -q "All steps completed successfully" test_wasm_node.log

emmake make -C wasm-build install

# The kernel (src/post.js) loads the Init/Std/Lean oleans as per-module zstd
# tarballs listed in manifest-v2.json, so ship those instead of the ~1.7GB raw tree.
OLEAN_DIR=${PREFIX}/share/jupyter/olean
bash scripts/pack-olean-modules.sh ${OLEAN_DIR} _olean_packed ""
rm -rf ${OLEAN_DIR}
mkdir -p ${OLEAN_DIR}
cp _olean_packed/*-olean.tar.zst _olean_packed/manifest-v2.json ${OLEAN_DIR}/
