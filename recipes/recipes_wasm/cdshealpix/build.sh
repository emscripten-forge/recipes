#!/bin/bash
set -euxo pipefail

# Copy the cdshealpix Rust crate pinned in Cargo.lock out of the cargo
# registry, so it can be patched and used through [patch.crates-io]
cargo fetch --locked
vendor_crate() {
  local ver
  # the registry entry (Cargo.lock also lists this binding as "cdshealpix")
  ver=$(awk -v n="\"$1\"" '$1 == "name" && $3 == n { getline; v = $3; getline; if ($0 ~ /registry\+/) { gsub(/"/, "", v); print v; exit } }' Cargo.lock)
  cp -R "$(ls -d "${CARGO_HOME:-$HOME/.cargo}"/registry/src/*/"$1-$ver" | head -1)" "$1-crate"
}
vendor_crate cdshealpix

# show_with_default_app only exists for linux/macos/windows in the crate
cat >> cdshealpix-crate/src/nested/map/img.rs <<'EOF'

#[cfg(not(any(target_os = "linux", target_os = "macos", target_os = "windows")))]
pub fn show_with_default_app(path: &str) -> Result<(), io::Error> {
  let _ = path;
  Err(io::Error::new(
    io::ErrorKind::Unsupported,
    "no default image viewer on this platform",
  ))
}
EOF

# use the patched cdshealpix crate instead of crates.io
cat >> Cargo.toml <<EOF

[patch.crates-io]
cdshealpix = { path = "cdshealpix-crate" }
EOF

export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_${target_platform#emscripten-}-emscripten.py
${PYTHON} -m pip install . -vv ${PIP_ARGS}
