if [ -z ${CONDA_FORGE_EMSCRIPTEN_WASM_32_ACTIVATED+x} ]; then

    export CONDA_FORGE_EMSCRIPTEN_WASM_32_ACTIVATED=1
    export MESON_CROSS_FILE="${BUILD_PREFIX}/etc/emscripten.meson.cross"
fi