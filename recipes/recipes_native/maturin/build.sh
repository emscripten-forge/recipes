#!/bin/bash
# Build maturin with wasm64-unknown-emscripten support.
#
# This is a native build: maturin is a host tool that drives cargo, so it is
# built for the build platform with rust-nightly (which lives in $PREFIX/bin).

set -euxo pipefail

# The emscripten-forge environment targets a wasm cross build; maturin is a
# native binary.
unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
unset EM_FORGE_OPTFLAGS EM_FORGE_DBGFLAGS EM_FORGE_LDFLAGS_BASE \
      EM_FORGE_CFLAGS_BASE EM_FORGE_SIDE_MODULE_LDFLAGS EM_FORGE_SIDE_MODULE_CFLAGS
unset CC CXX AR RANLIB
unset CARGO_BUILD_TARGET

# conda-forge's maturin recipe uses the same feature set; keep it identical so
# this build only differs by the wasm64 patch.
export MATURIN_SETUP_ARGS="--no-default-features --features=full,native-tls,password-storage"
export OPENSSL_NO_VENDOR=1
export OPENSSL_DIR="${PREFIX}"

"${PYTHON}" -m pip install . -vv --no-build-isolation
