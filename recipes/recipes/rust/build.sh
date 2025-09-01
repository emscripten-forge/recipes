# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for TASK in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${TASK}.d"
    cp "${RECIPE_DIR}/${TASK}.sh" "${PREFIX}/etc/conda/${TASK}.d/${TASK}_${PKG_NAME}.sh"
done

export RUSTUP_HOME=$HOME/.rustup_emscripten_forge
export CARGO_HOME=$HOME/.cargo_emscripten_forge
export PATH=$CARGO_HOME/bin:$PATH

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y #--default-toolchain=1.78.0
rustup install nightly-2025-08-07
rustup default nightly-2025-08-07
rustup target add wasm32-unknown-emscripten
