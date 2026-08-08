#!/bin/bash
set -ex 

# =========================================================================
# PHASE 1: Build Js_of_ocaml bundle
# Use a subshell to isolate the environment changes
# =========================================================================
(
  # --- Disable OCaml-related wasm flags: OCaml needs native builders ---
  unset CC CXX CFLAGS CXXFLAGS LDFLAGS OPAMSWITCH
  # --- Private opam root built into the source tree (no cross-build caching) ---
  export OPAMROOT=$SRC_DIR/opam_root

  cd ocaml
  opam init --disable-sandboxing --no --compiler=5.5.0
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

# Clear the host (native) LDFLAGS: CMake reads LDFLAGS into the linker flags,
# and the native `-Wl,--no-pie/--sort-common/--as-needed` flags are rejected
# by wasm-ld.
unset LDFLAGS

cmake -S ${SRC_DIR} -GNinja ${CMAKE_ARGS}    \
    -DCMAKE_BUILD_TYPE=Release               \
    -DCMAKE_PREFIX_PATH=${PREFIX}            \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}

ninja install