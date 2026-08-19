if [ -z ${CONDA_FORGE_EMSCRIPTEN_WASM_64_ACTIVATED+x} ]; then


    echo "Activating emscripten_emscripten-wasm64 environment variables"

    export CONDA_FORGE_EMSCRIPTEN_WASM_64_ACTIVATED=1

    # these flags are passed to emcc, so every package built with emcc gets them
    export EMCC_CFLAGS="${EMCC_CFLAGS} -m64"

fi