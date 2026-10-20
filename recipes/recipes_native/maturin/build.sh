#!/bin/bash

set -euxo pipefail

unset CARGO_BUILD_TARGET
unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
unset CC CXX AR RANLIB

export MATURIN_SETUP_ARGS="--no-default-features --features=full,native-tls,password-storage"
export OPENSSL_NO_VENDOR=1
export OPENSSL_DIR="${PREFIX}"

"${PYTHON}" -m pip install . -vv --no-build-isolation
