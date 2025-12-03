# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for TASK in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${TASK}.d"
    cp "${RECIPE_DIR}/${TASK}.sh" "${PREFIX}/etc/conda/${TASK}.d/${TASK}_${PKG_NAME}.sh"
done

set -eux

export RUSTUP_HOME=$PREFIX/.rustup_emscripten_forge
export CARGO_HOME=$PREFIX/.cargo_emscripten_forge

# info: latest update on 2025-11-10, rust version 1.91.1 (ed61e7d7e 2025-11-07)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    --no-modify-path \
    --default-toolchain nightly \
    --profile minimal \
    --target wasm32-unknown-emscripten \
    -y

RUSTC_DATE=$(rustc --version | cut -d' ' -f4 | tr -d '()')
# RUSTC_DATE="2025-12-01"
wget --quiet https://static.rust-lang.org/dist/${RUSTC_DATE}/channel-rust-nightly.toml

# Get the git_commit_hash for pkg.rust
COMMIT_HASH=$(grep -A 2 "\[pkg.rust\]" channel-rust-nightly.toml | grep git_commit_hash | cut -d'"' -f2)

git clone https://github.com/rust-lang/rust.git --shallow-since=2025-01-01
cd rust
git reset --hard
git checkout $COMMIT_HASH

# https://github.com/pyodide/rust-emscripten-wasm-eh-sysroot/blob/main/turn-on-emscripten-wasm-eh.patch
sed -i 's/emscripten_wasm_eh: bool = (false, parse_bool, \[TRACKED\],/\
          emscripten_wasm_eh: bool = (true, parse_bool, [TRACKED],/' \
          compiler/rustc_session/src/options.rs

# Use nightly rustc and cargo
export PATH=$CARGO_HOME/bin:$PATH
export RUSTC_BIN=$(which rustc)
export CARGO_BIN=$(which cargo)

envsubst < $RECIPE_DIR/config.toml > ./config.toml
envsubst '$PREFIX' < $RECIPE_DIR/bootstrap.toml > ./bootstrap.toml

cat config.toml

./x build --stage 2 --target wasm32-unknown-emscripten
./x build library --stage 2 --target wasm32-unknown-emscripten
./x build library --stage 2 --target x86_64-unknown-linux-gnu

CUSTOM_TOOLCHAIN="${RUSTUP_HOME}/rust-toolchain-wasm-eh"
mkdir -p $CUSTOM_TOOLCHAIN
cp -r build/host/stage2/* $CUSTOM_TOOLCHAIN/
rustup toolchain link rust-toolchain-wasm-eh $CUSTOM_TOOLCHAIN
rustup default rust-toolchain-wasm-eh

# # Need to install and then remove the target so that it is recognized as active
# RUST_TOOLCHAIN=$(rustup show active-toolchain | awk '{print $1}')

# rm -r $RUSTUP_HOME/toolchains/$RUST_TOOLCHAIN/lib/rustlib/wasm32-unknown-emscripten
# cp -r build/host/stage1/lib/rustlib/wasm32-unknown-emscripten \
#     $RUSTUP_HOME/toolchains/$RUST_TOOLCHAIN/lib/rustlib/
rustup toolchain list
rustc --version
rustup --version

# # Copy everything
# rm $RUSTUP_HOME/toolchains/$RUST_TOOLCHAIN/bin/rustc
# cp build/host/stage1/bin/rustc $RUSTUP_HOME/toolchains/$RUST_TOOLCHAIN/bin/
# cp build/host/stage1/lib/librustc_driver-*.so $RUSTUP_HOME/toolchains/$RUST_TOOLCHAIN/lib/
# cp -r build/host/stage0/lib/rustlib/x86_64-unknown-linux-gnu \
#     $RUSTUP_HOME/toolchains/$RUST_TOOLCHAIN/lib/rustlib/
