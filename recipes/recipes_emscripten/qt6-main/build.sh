#!/usr/bin/env bash
set -e

# Qt6 for WebAssembly. Cross-compile qtbase using the emscripten toolchain.
#
# Qt's cross-compile needs a host Qt install so tools like moc/rcc/uic/qmake
# can run natively during configure and build. We get that from qt6-main
# in $BUILD_PREFIX (from conda-forge).

QT_HOST_PATH="${BUILD_PREFIX}"

# Qt's configure looks for EMSDK; emscripten-forge sets EMSCRIPTEN_FORGE_EMSDK_DIR.
# Qt's QtPublicWasmToolchainHelpers.cmake reads $EMSDK/.emscripten and extracts
# the single-quoted value of EMSCRIPTEN_ROOT, then joins as $EMSDK/<that>/emcc.
# The value must therefore be a *relative* path under EMSDK — an absolute path
# gets concatenated to $EMSDK/$EMSDK/... and the emcc lookup fails.
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

mkdir build && cd build

# `configure` is Qt's wrapper around cmake — it knows the wasm-emscripten
# platform mnemonic and sets the right toolchain file for us.
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
