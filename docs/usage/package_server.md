# Package Server

Emscripten-forge packages are hosted on  [prefix.dev](https://prefix.dev/channels/emscripten-forge-dev).

!!! note

    To use emscripten-forge conda packages, you need to add the `emscripten-forge` channel to your conda configuration or use the `--channel` flag when installing packages, ie:

    ```bash
    micromamba create -n myenv --platform=emscripten-wasm32 \
        -c https://prefix.dev/channels/emscripten-forge-dev \
        -c conda-forge \
        python numpy
    ```
