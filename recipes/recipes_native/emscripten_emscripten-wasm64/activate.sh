if [ -z ${CONDA_FORGE_EMSCRIPTEN_WASM_64_ACTIVATED+x} ]; then



    export CONDA_FORGE_EMSCRIPTEN_WASM_64_ACTIVATED=1
    export MESON_CROSS_FILE="${BUILD_PREFIX}/etc/emscripten.meson.cross"

    # these flags are passed to emcc, so every package built with emcc gets them
    export EMCC_CFLAGS="${EMCC_CFLAGS} -m64"

fi