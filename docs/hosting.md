# Quetz Server

Emscripten forge packages are hosted as 
as a the [emscripten-forge](https://beta.mamba.pm/channels/emscripten-forge) channel on a [Quetz](https://quetz.io/) server. 
on a [Quetz](https://quetz.io/) server.

!!! note
    To use emscripten-forge conda packages, you need to add the `emscripten-forge` channel to your conda configuration or use the `--channel` flag when installing packages, ie:

    ```bash
    micromamba create -n myenv --platform=emscripten-wasm32 \
        -c https://repo.mamba.pm/emscripten-forge \
        -c conda-forge \
        python numpy
    ```