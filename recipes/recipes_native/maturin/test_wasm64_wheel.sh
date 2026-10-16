#!/bin/bash
# End-to-end check of the wasm64 patch: build a real PyO3 extension module for
# wasm64-unknown-emscripten and assert maturin emits a _wasm64 wheel.

set -euxo pipefail

maturin --version

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)/tests"
cd "${WORK}"

cp -r "${TESTS_DIR}/pyo3test" "${TESTS_DIR}/sysconfig" "${WORK}/"

# pyo3-build-config cross builds read the target's sysconfigdata; the
# sysconfig/ folder provides the minimal subset it needs for the wasm64 triple.
cd pyo3test
PYO3_CROSS=1 \
PYO3_CROSS_LIB_DIR="${WORK}/sysconfig" \
PYO3_CROSS_PYTHON_VERSION=3.13 \
PYO3_CROSS_PYTHON_IMPLEMENTATION=CPython \
maturin build --release --target wasm64-unknown-emscripten

ls target/wheels/
compgen -G 'target/wheels/*_wasm64.whl' > /dev/null
