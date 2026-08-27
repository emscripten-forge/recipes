#!/usr/bin/env bash
set -e

echo "=== qtsvg build platforms ==="
echo "build_platform=${build_platform:-<unset>}"
echo "host_platform=${host_platform:-<unset>}"
echo "target_platform=${target_platform:-<unset>}"
echo "============================="

# Qt6Svg add-on module. Links against the wasm qt6-main in $PREFIX and uses
# native qt6-main host tools from $BUILD_PREFIX.

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

cd qtsvg
mkdir build && cd build

# qt-configure-module wraps cmake with the right toolchain + target-Qt discovery.
# QT_HOST_PATH still needs to be passed explicitly for the cross-compile.
"${PREFIX}/bin/qt-configure-module" .. \
    -- \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DQT_HOST_PATH="${BUILD_PREFIX}"

ninja -j "${CPU_COUNT:-2}"
ninja install
