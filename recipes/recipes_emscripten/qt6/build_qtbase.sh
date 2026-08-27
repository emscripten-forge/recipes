#!/usr/bin/env bash
set -e

echo "=== qtbase build platforms ==="
echo "build_platform=${build_platform:-<unset>}"
echo "host_platform=${host_platform:-<unset>}"
echo "target_platform=${target_platform:-<unset>}"
echo "==============================="

# Qt6 base — cross-compile qtbase for Emscripten.
# Host tools (moc/rcc/uic/qt-cmake-*) come from native qt6-main in $BUILD_PREFIX.

QT_HOST_PATH="${BUILD_PREFIX}"

# Qt's QtPublicWasmToolchainHelpers.cmake reads $EMSDK/.emscripten and expects
# EMSCRIPTEN_ROOT to be a *relative* path under $EMSDK. emscripten-forge doesn't
# ship a .emscripten file, so synthesise one.
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

cd qtbase
mkdir build && cd build

# Qt's `configure` wraps cmake and knows the wasm-emscripten platform mnemonic.
../configure \
    -platform wasm-emscripten \
    -qt-host-path "${QT_HOST_PATH}" \
    -prefix "${PREFIX}" \
    -static \
    -release \
    -opensource -confirm-license \
    -no-warnings-are-errors \
    -nomake examples -nomake tests \
    -no-feature-cups -no-feature-vulkan -no-feature-dbus \
    -no-pch \
    -- \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}"

# Don't use `cmake --build` — the emscripten-forge activation wraps `cmake`
# and prepends toolchain -D flags, which cmake rejects on --build invocations.
ninja -j "${CPU_COUNT:-2}"
ninja install
