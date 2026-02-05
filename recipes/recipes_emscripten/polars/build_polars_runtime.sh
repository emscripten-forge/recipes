#!/usr/bin/env bash

set -euxo pipefail

cd $PKG_NAME

export CARGO_PROFILE_RELEASE_STRIP=symbols
export RUSTFLAGS="${RUSTFLAGS} -C link-arg=--no-entry"
# Deactivate warnings as they are too many (probably created to deactivated features)
export RUSTFLAGS="-A warnings"

# FIXME should be fixed in emscripten-forge but we currenty need this step
rustup target add wasm32-unknown-emscripten

# Polars for emscripten-wams32 does not currently have a clean build
# In CI it is tested with the following build steps
# TODO worth checking on every release to see if features are changing.
# see https://github.com/pola-rs/polars/blob/main/.github/workflows/test-pyodide.yml
FEATURES="csv|ipc|ipc_streaming|parquet|async|scan_lines|json|extract_jsonpath|catalog|cloud|polars_cloud|tokio|clipboard|decompress|new_streaming"
sed -i 's/serde_json = { workspace = true, optional = true }/serde_json = { workspace = true }/' crates/polars-python/Cargo.toml
sed -i 's/"serde_json", //' crates/polars-python/Cargo.toml
sed -E -i "/^  \"(${FEATURES})\",$/d" crates/polars-python/Cargo.toml py-polars/runtime/polars-runtime-32/Cargo.toml

"${PYTHON}" -m pip install --no-deps --no-build-isolation . -vv


# From conda-forge:
# The root level Cargo.toml is part of an incomplete workspace
# we need to use the manifest inside the py-polars
cd py-polars/runtime
cargo-bundle-licenses --format yaml --output ../../THIRDPARTY.yml
