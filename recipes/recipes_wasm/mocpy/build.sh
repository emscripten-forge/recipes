#!/bin/bash
set -euxo pipefail

# the .crate sources are downloaded as-is (rattler does not unpack .crate)
tar xzf moc-crate/moc-0.19.2.tar.gz -C moc-crate --strip-components=1
tar xzf cdshealpix-crate/cdshealpix-0.9.1.tar.gz -C cdshealpix-crate --strip-components=1

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

# use the patched crates (see recipe.yaml) instead of crates.io
cat >> Cargo.toml <<EOF

[patch.crates-io]
moc = { path = "moc-crate" }
cdshealpix = { path = "cdshealpix-crate" }
EOF

export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_${target_platform#emscripten-}-emscripten.py
${PYTHON} -m pip install . -vv ${PIP_ARGS}
