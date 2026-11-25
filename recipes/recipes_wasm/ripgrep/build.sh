export RUSTFLAGS="\
    -C link-arg=--minify=0 \
    -C link-arg=-sALLOW_MEMORY_GROWTH=1 \
    -C link-arg=-sEXIT_RUNTIME=1 \
    -C link-arg=-sEXPORTED_FUNCTIONS=_main,_raise \
    -C link-arg=-sEXPORTED_RUNTIME_METHODS=FS,ENV,TTY \
    -C link-arg=-sFORCE_FILESYSTEM=1 \
    -C link-arg=-sMODULARIZE=1 \
    "

# Let the pcre2-sys build script use pkg-config when cross-compiling, so that
# it finds the pcre2-static package rather than building its bundled PCRE2.
export PKG_CONFIG_ALLOW_CROSS=1
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

# Stop ripgrep's build script picking up the git revision of the enclosing recipes repo.
export GIT_CEILING_DIRECTORIES=$(dirname $SRC_DIR)

# CARGO_BUILD_TARGET is set by the rust-nightly activation script.
# Optimise for size rather than speed.
cargo build --profile release-lto --features pcre2 --config 'profile.release-lto.opt-level="s"'

mkdir -p $PREFIX/bin
# cargo does not copy rg.wasm to the top-level output directory for wasm64.
OUT_DIR=$(dirname $(find target/$CARGO_BUILD_TARGET/release-lto/build -name rg.wasm))
cp $OUT_DIR/rg.{js,wasm} $PREFIX/bin/
