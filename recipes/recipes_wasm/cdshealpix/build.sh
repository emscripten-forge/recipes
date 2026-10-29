#!/bin/bash
set -euxo pipefail

# the .crate source is downloaded as-is (rattler does not unpack .crate)
tar xzf cdshealpix-crate/cdshealpix-0.10.1.tar.gz -C cdshealpix-crate --strip-components=1

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

# use the patched cdshealpix crate (see recipe.yaml) instead of crates.io
cat >> Cargo.toml <<EOF

[patch.crates-io]
cdshealpix = { path = "cdshealpix-crate" }
EOF

export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_${target_platform#emscripten-}-emscripten.py
${PYTHON} -m pip install . -vv ${PIP_ARGS}
