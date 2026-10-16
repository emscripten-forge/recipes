#!/bin/bash

set -euxo pipefail

unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
unset EM_FORGE_OPTFLAGS EM_FORGE_DBGFLAGS EM_FORGE_LDFLAGS_BASE \
      EM_FORGE_CFLAGS_BASE EM_FORGE_SIDE_MODULE_LDFLAGS EM_FORGE_SIDE_MODULE_CFLAGS
unset CC CXX AR RANLIB
unset CARGO_BUILD_TARGET

export MATURIN_SETUP_ARGS="--no-default-features --features=full,native-tls,password-storage"
export OPENSSL_NO_VENDOR=1
export OPENSSL_DIR="${PREFIX}"

"${PYTHON}" -m pip install . -vv --no-build-isolation
