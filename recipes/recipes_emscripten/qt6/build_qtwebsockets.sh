#!/usr/bin/env bash
set -e

export EMSDK="${EMSCRIPTEN_FORGE_EMSDK_DIR}"
export EMSDK_NODE=$(command -v node)

if [ ! -f "${EMSDK}/.emscripten" ]; then
    cat > "${EMSDK}/.emscripten" <<EOF
LLVM_ROOT = '${EMSDK}/upstream/bin'
BINARYEN_ROOT = '${EMSDK}/upstream'
EMSCRIPTEN_ROOT = 'upstream/emscripten'
NODE_JS = '${EMSDK_NODE}'
COMPILER_ENGINE = NODE_JS
JS_ENGINES = [NODE_JS]
EOF
fi

cd qtwebsockets
mkdir build && cd build

"${PREFIX}/bin/qt-configure-module" .. \
    -- \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DQT_HOST_PATH="${BUILD_PREFIX}"

ninja -j "${CPU_COUNT:-2}"
ninja install
