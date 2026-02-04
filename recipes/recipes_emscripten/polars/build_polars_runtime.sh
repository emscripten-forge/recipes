#!/usr/bin/env bash

set -euxo pipefail

cd $PKG_NAME

export CARGO_PROFILE_RELEASE_STRIP=symbols

$PYTHON -m pip install . -vv

# The root level Cargo.toml is part of an incomplete workspace
# we need to use the manifest inside the py-polars
cd py-polars/runtime
cargo-bundle-licenses --format yaml --output ../../THIRDPARTY.yml
