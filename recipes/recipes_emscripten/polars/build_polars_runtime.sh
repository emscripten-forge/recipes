#!/usr/bin/env bash

set -euxo pipefail

cd $PKG_NAME

export CARGO_PROFILE_RELEASE_STRIP=symbols

MATURIN_PEP517_ARGS="--exclude-features async \
    --exclude-features aws                \
    --exclude-features azure              \
    --exclude-features cloud              \
    --exclude-features decompress         \
    --exclude-features default            \
    --exclude-features docs-selection     \
    --exclude-features extract_jsonpath   \
    --exclude-features fmt                \
    --exclude-features gcp                \
    --exclude-features csv                \
    --exclude-features ipc                \
    --exclude-features ipc_streaming      \
    --exclude-features json               \
    --exclude-features nightly            \
    --exclude-features parquet            \
    --exclude-features performant         \
    --exclude-features streaming          \
    --exclude-features http               \
    --exclude-features full               \
    --exclude-features test"

$PYTHON -m pip install . -vv

# The root level Cargo.toml is part of an incomplete workspace
# we need to use the manifest inside the py-polars
cd py-polars/runtime
cargo-bundle-licenses --format yaml --output ../../THIRDPARTY.yml
