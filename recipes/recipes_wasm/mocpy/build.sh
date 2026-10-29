#!/bin/bash
set -euxo pipefail

# Copy the moc and cdshealpix Rust crates pinned in Cargo.lock out of the
# cargo registry, so they can be patched and used through [patch.crates-io]
cargo fetch --locked
vendor_crate() {
  local ver
  ver=$(awk -v n="\"$1\"" '$1 == "name" && $3 == n { getline; v = $3; getline; if ($0 ~ /registry\+/) { gsub(/"/, "", v); print v; exit } }' Cargo.lock)
  cp -R "$(ls -d "${CARGO_HOME:-$HOME/.cargo}"/registry/src/*/"$1-$ver" | head -1)" "$1-crate"
}
vendor_crate moc
vendor_crate cdshealpix

# show_with_default_app only exists for linux/macos/windows in both crates
add_fallback() {
  cat >> "$1" <<EOF

#[cfg(not(any(target_os = "linux", target_os = "macos", target_os = "windows")))]
$2 show_with_default_app(path: &str) -> Result<(), io::Error> {
  let _ = path;
  Err(io::Error::new(
    io::ErrorKind::Unsupported,
    "no default image viewer on this platform",
  ))
}
EOF
}
add_fallback moc-crate/src/deser/img.rs "fn"
add_fallback cdshealpix-crate/src/nested/map/img.rs "pub fn"

# use the patched crates instead of crates.io
cat >> Cargo.toml <<EOF

[patch.crates-io]
moc = { path = "moc-crate" }
cdshealpix = { path = "cdshealpix-crate" }
EOF

export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_${target_platform#emscripten-}-emscripten.py
${PYTHON} -m pip install . -vv ${PIP_ARGS}
