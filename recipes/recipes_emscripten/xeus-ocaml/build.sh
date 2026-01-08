#!/bin/bash
set -ex 

# =========================================================================
# PHASE 1: Build Js_of_ocaml bundle
# Use a subshell to isolate the environment changes
# =========================================================================
(
  unset CC CXX CFLAGS CXXFLAGS LDFLAGS

  cd ocaml
  opam init --disable-sandboxing --no --compiler=5.4.0
  opam install dune
  opam exec -- dune pkg lock
  opam exec -- dune build --profile release
)

# Copy the build artifacts
mkdir -p ocaml-build
cp -r ocaml/_build/default/src/* ocaml-build/

# =========================================================================
# PHASE 2: Build Xeus WASM kernel
# Here, the standard rattler-build environment variables are available again
# =========================================================================
mkdir -p build
cd build

cmake -S ${SRC_DIR} -GNinja ${CMAKE_ARGS}    \
    -DCMAKE_BUILD_TYPE=Release               \
    -DCMAKE_PREFIX_PATH=${PREFIX}            \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}

ninja install