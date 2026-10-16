#!/bin/bash
# End-to-end check of the wasm64 patch: build a real PyO3 extension module for
# wasm64-unknown-emscripten and assert maturin emits a _wasm64 wheel.
#
# Without the patch maturin aborts with "The architecture wasm64 is not
# supported" before cargo is ever invoked; with it the wheel is named
# `...emscripten_<ver>_wasm64.whl` (a `_wasm32` name means a wasm32 object was
# silently produced, which fails at import time with
# "cannot import i64 memory as i32").
set -euxo pipefail

maturin --version

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
cd "${WORK}"

# Minimal PyO3 extension module; abi3 keeps the wheel independent of a concrete
# Python build, so no wasm Python interpreter is needed for the build.
mkdir -p pyo3test/src
cat > pyo3test/Cargo.toml <<'TOML'
[package]
name = "pyo3test"
version = "0.1.0"
edition = "2021"

[lib]
name = "pyo3test"
crate-type = ["cdylib"]

[dependencies]
pyo3 = { version = "0.27", default-features = false, features = ["extension-module", "abi3-py313", "macros"] }
TOML
cat > pyo3test/src/lib.rs <<'RS'
use pyo3::prelude::*;

#[pyfunction]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[pymodule]
fn pyo3test(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(add, m)?)?;
    Ok(())
}
RS

# pyo3-build-config cross builds read the target's sysconfigdata; provide the
# minimal subset it needs for the wasm64 triple.
mkdir -p sysconfig
cat > sysconfig/_sysconfigdata__emscripten_wasm64-emscripten.py <<'PY'
build_time_vars = {
    'SOABI': 'cpython-313-wasm64-emscripten',
    'Py_DEBUG': 0,
    'Py_GIL_DISABLED': 0,
    'SIZEOF_VOID_P': 8,
    'Py_ENABLE_SHARED': 0,
    'VERSION': '3.13',
    'ABIFLAGS': '',
    'LDVERSION': '3.13',
}
PY

cd pyo3test
PYO3_CROSS=1 \
PYO3_CROSS_LIB_DIR="${WORK}/sysconfig" \
PYO3_CROSS_PYTHON_VERSION=3.13 \
PYO3_CROSS_PYTHON_IMPLEMENTATION=CPython \
maturin build --release --target wasm64-unknown-emscripten

ls target/wheels/
compgen -G 'target/wheels/*_wasm64.whl' > /dev/null
