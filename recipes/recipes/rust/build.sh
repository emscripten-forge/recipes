mkdir -p ${PREFIX}/etc/conda/activate.d
mkdir -p ${PREFIX}/etc/conda/deactivate.d


cp "${RECIPE_DIR}"/activate-rust.sh   ${PREFIX}/etc/conda/activate.d/activate_z-${PKG_NAME}.sh
cp "${RECIPE_DIR}"/deactivate-rust.sh ${PREFIX}/etc/conda/deactivate.d/deactivate_z-${PKG_NAME}.sh

export RUSTUP_HOME=$HOME/.rustup_emscripten_forge
export CARGO_HOME=$HOME/.cargo_emscripten_forge
export PATH=$CARGO_HOME/bin:$PATH

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y #--default-toolchain=1.78.0
rustup install nightly-2025-01-09
rustup default nightly-2025-01-09
rustup target add wasm32-unknown-emscripten