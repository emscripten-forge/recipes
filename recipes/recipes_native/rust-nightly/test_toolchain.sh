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

# Link a cdylib for the new target with the package's own defaults: this
# exercises the wasm64 std, the linker, and the target's link arguments.
cat > /tmp/smoke.rs <<'RS'
use std::ffi::c_void;

#[unsafe(no_mangle)]
pub extern "C" fn smoke_add(a: i64, b: i64) -> i64 {
    let v: Vec<i64> = (0..8).map(|i| i * a).collect();
    std::hint::black_box(v.as_ptr() as *const c_void);
    a + b + v[1]
}
RS

rustc --crate-type=cdylib -O /tmp/smoke.rs \
    --target wasm64-unknown-emscripten -Cpanic=abort -o /tmp/smoke.wasm
test -s /tmp/smoke.wasm

rustc --crate-type=cdylib -O /tmp/smoke.rs \
    --target wasm32-unknown-emscripten -Cpanic=abort -o /tmp/smoke32.wasm
test -s /tmp/smoke32.wasm
