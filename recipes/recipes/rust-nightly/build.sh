# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for TASK in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${TASK}.d"
    cp "${RECIPE_DIR}/${TASK}.sh" "${PREFIX}/etc/conda/${TASK}.d/${TASK}_${PKG_NAME}.sh"
done

export RUSTUP_HOME=$PREFIX/.rustup_emscripten_forge
export CARGO_HOME=$PREFIX/.cargo_emscripten_forge

# info: latest update on 2025-11-10, rust version 1.91.1 (ed61e7d7e 2025-11-07)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    --no-modify-path \
    --default-toolchain nightly \
    --profile minimal \
    --target wasm32-unknown-emscripten \
    -y
