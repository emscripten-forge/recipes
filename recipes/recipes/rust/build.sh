mkdir -p ${PREFIX}/etc/conda/activate.d
mkdir -p ${PREFIX}/etc/conda/deactivate.d


cp "${RECIPE_DIR}"/activate-rust.sh   ${PREFIX}/etc/conda/activate.d/activate_z-${PKG_NAME}.sh
cp "${RECIPE_DIR}"/deactivate-rust.sh ${PREFIX}/etc/conda/deactivate.d/deactivate_z-${PKG_NAME}.sh




echo "Activating Rust"

# export RUSTUP_HOME=$PREFIX/.rustup
export CARGO_HOME=$PREFIX/.cargo
export PATH=$CARGO_HOME/bin:$PATH


curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain=$PKG_VERSION
rustup default $PKG_VERSION
rustup target add wasm32-unknown-emscripten

