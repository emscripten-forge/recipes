#!/usr/bin/env bash
set -e

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
    -feature-wasm-exceptions \
    ${QT_EXTRA_FEATURES:-} \
    -no-pch \
    -- \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}"

# Don't use `cmake --build` — the emscripten-forge activation wraps `cmake`
# and prepends toolchain -D flags, which cmake rejects on --build invocations.
ninja -j "${CPU_COUNT:-2}"
ninja install

# Post-install: Qt's cross-install generates wrapper scripts under
# $PREFIX/bin (qmake6, qtpaths6, qt-cmake, ...) that hardcode the
# build-time absolute path of the *native* qmake6/cmake in $BUILD_PREFIX.
# When the package is installed on a different machine those paths don't
# exist, so `qmake6` fails with "No such file or directory". Rewrite the
# baked-in build-time prefix to a $QT_HOST_PATH reference — downstream
# users already set QT_HOST_PATH for the cmake cross-compile flow, so
# they get qmake for free with no additional setup.
for w in qmake qmake6 qtpaths qtpaths6 qt-cmake qt-cmake-create; do
    f="${PREFIX}/bin/${w}"
    [ -f "${f}" ] || continue
    sed -i "s|${BUILD_PREFIX}|\${QT_HOST_PATH:?QT_HOST_PATH must be set for Qt cross-compile}|g" "${f}"
done
