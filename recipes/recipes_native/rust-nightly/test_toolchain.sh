#!/bin/bash
# Verify the installed toolchain, including a real link for wasm64.
set -euxo pipefail

rustc --version

rustc --print target-list | grep -qx wasm32-unknown-emscripten
rustc --print target-list | grep -qx wasm64-unknown-emscripten

SYSROOT="$(rustc --print sysroot)"
HOST="$(rustc -vV | sed -n 's/^host: //p')"

# Standard library for both Emscripten targets.
test -d "${SYSROOT}/lib/rustlib/wasm32-unknown-emscripten/lib"
test -d "${SYSROOT}/lib/rustlib/wasm64-unknown-emscripten/lib"

# rust-src, needed by packages that build std with -Zbuild-std.
test -d "${SYSROOT}/lib/rustlib/src/rust/library"

# The self-contained linker must sit next to rustc, otherwise `-C
# link-self-contained` (the default for wasm) fails every link.
test -x "${SYSROOT}/lib/rustlib/${HOST}/bin/gcc-ld/wasm-ld"

SMOKE_SRC=tests/smoke.rs

rustc --crate-type=cdylib -O "${SMOKE_SRC}" \
    --target wasm64-unknown-emscripten -Cpanic=abort -o /tmp/smoke.wasm
test -s /tmp/smoke.wasm

rustc --crate-type=cdylib -O "${SMOKE_SRC}" \
    --target wasm32-unknown-emscripten -Cpanic=abort -o /tmp/smoke32.wasm
test -s /tmp/smoke32.wasm

# std's libc must agree with emscripten's C headers: link Rust and C code
# that both call poll() (nfds_t is 32-bit on wasm64 since emscripten 6.0.1)
emcc -c tests/poll_user.c -sMEMORY64=1 -o /tmp/poll_user64.o
rustc --crate-type=cdylib -O tests/poll_abi.rs \
    --target wasm64-unknown-emscripten -Cpanic=abort \
    -C link-arg=/tmp/poll_user64.o -o /tmp/poll_abi64.wasm
test -s /tmp/poll_abi64.wasm

emcc -c tests/poll_user.c -o /tmp/poll_user32.o
rustc --crate-type=cdylib -O tests/poll_abi.rs \
    --target wasm32-unknown-emscripten -Cpanic=abort \
    -C link-arg=/tmp/poll_user32.o -o /tmp/poll_abi32.wasm
test -s /tmp/poll_abi32.wasm
