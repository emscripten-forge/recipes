# Installing packages

## Install packages with micromamba
We recommend using micromamba to install packages from this channel.
To install micromamba itself, follow the instructions in the [micromamba documentation](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html#micromamba-installation).

To install packages from this channel, use the following command:

```bash
micromamba create -n my-channel-name \
    --platform=emscripten-wasm32 \
    -c https://repo.prefix.dev/emscripten-forge-4x\
    -c https://repo.prefix.dev/conda-forge \
    --yes \
    python numpy scipy matplotlib
```

All noarch packages are installed from the `conda-forge` channel, all packages compiled for the `emscripten-wasm32` platform are provided via the `emscripten-forge` channel.
