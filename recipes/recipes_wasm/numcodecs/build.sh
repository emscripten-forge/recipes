#!/bin/bash
set -euxo pipefail

# numcodecs >= 0.17 builds with meson-python; no SIMD on wasm.
# meson finds numpy through pkg-config: use the host (wasm) numpy's numpy.pc
export PKG_CONFIG_PATH="${PREFIX}/lib/python${PY_VER}/site-packages/numpy/_core/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$MESON_CROSS_PYTHON_FILE" \
    -Csetup-args="-Dsse2=disabled" \
    -Csetup-args="-Davx2=disabled"
