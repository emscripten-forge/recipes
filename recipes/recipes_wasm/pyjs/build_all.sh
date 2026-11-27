#!/bin/bash
set -ex

# Specific variables for cross-compilation
if [[ "$target_platform" == "emscripten-wasm32" ]]; then
    USE_WASM64=FALSE
    M64_FLAGS=""
elif [[ "$target_platform" == "emscripten-wasm64" ]]; then
    # -m64 must be in CMAKE_C_FLAGS on the command line (Emscripten.cmake decides
    # 32 / 64 bit from it) and in EMCC_CFLAGS (every emcc call, e.g. the ports)
    USE_WASM64=TRUE
    M64_FLAGS="-m64"
    export EMCC_CFLAGS="${EMCC_CFLAGS} -m64"
else
    echo "Unsupported target_platform: $target_platform"
    exit 1
fi

# detect python version (e.g. 3.14)
PY_VER=$(basename "$PREFIX"/include/python3.* | sed 's/^python//')
echo "Detected Python version:" $PY_VER

# libpyjs + the runtime (pyjs_runtime_browser.{js,wasm}) + the python module,
# all installed into $PREFIX (the host env, which is also where the static
# libraries are linked from). Needs esbuild on PATH (src/js -> libpyjs) and
# nanobind in the host env's site-packages.
# (The JavaScript of the npm package is the output pyjs-npm, see recipe.yaml.)
emcmake cmake ${CMAKE_ARGS} -S . -B _build_conda \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_C_FLAGS="${M64_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${M64_FLAGS}" \
    -DWASM64=$USE_WASM64 \
    -DPY_VERSION=$PY_VER

# (`cmake` is wrapped by emcmake in the build env, which breaks `cmake --build`)
cd _build_conda
emmake make -j${CPU_COUNT:-4}
emmake make install
