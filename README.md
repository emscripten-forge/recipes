#  Emscripten forge
[![CI](https://img.shields.io/badge/emscripten_forge-docs-yellow)](https://emscripten-forge.org)
[![CI](https://img.shields.io/badge/emscripten_forge-blog-pink)](https://emscripten-forge.org)
 
Build wasm/emscripten packages with conda/mamba/boa.
This repository consists of recipes for conda packages for emscripten.


> **Note**
> We removed boa support from this repository. We are now using [rattler-build](https://github.com/prefix-dev/rattler-build).
> The recipes used in this repository follow the [rattler-build recipe format](https://github.com/prefix-dev/rattler-build?tab=readme-ov-file#the-recipe-format).

## Installing Packages
We recommend using micromamba to install packages from this channel.
```bash
micromamba create -n my-channel-name \
    --platform=emscripten-wasm32 \
    -c https://repo.mamba.pm/emscripten-forge \
    -c https://repo.mamba.pm/conda-forge \
    --yes \
    python numpy scipy matplotlib
```


## Adding Packages

To add a new package to emscripten-forge, just create a Pull Request in this repository.
This PR should add a new folder in the [recipe_emscripten](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten) folder
containing the recipe of your package.
A good example recipes is:
 
 * [regex](https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes_emscripten/regex/recipe.yaml) .
 
Once the PR is merged, the package is built and uploaded to https://beta.mamba.pm/channels/emscripten-forge




## Local Builds

To build a package locally, the easiest way is to use `pixi` (see [/pixi.sh/latest/#installation](https://pixi.sh/latest/#installation) for installation instructions).

```bash
# this only needs to be done once
pixi run setup 
# this builds the package
pixi run build-emscripten-wasm32-pkg recipes/recipes_emscripten/regex
```


## Local Builds with rattler-build
Only recipes with a `rattler_recipe.yaml` file can be built with `rattler-build`.


 **1** Create a new conda environment from `ci_env.yml` and install playwright in this environment:
 On a Linux / MacOS this can be done with:
```bash
micromamba create -n emscripten-forge -f ci_env.yml --yes
micromamba activate emscripten-forge
``` 


**All further steps should be executed in this environment.**
Ie if you open a new terminal, you have to activate the environment again with `micromamba activate emscripten-forge`.

**2** Setup emsdk:
 We currently need a patched version of emsdk. This is because emscripten had some regressions in the `3.1.45` release wrt. dynamic loading of shared libraries. We use the `./emsdk/setup_emsdk.sh` which takes
 two arguments: the emsdk version and the path where emsdk should be installed.
 In this example we choose `~/emsdk` as the installation path. You have to use version `3.1.45`.
 ```bash
./emsdk/setup_emsdk.sh 3.1.45 ~/emsdk
```

**2b** Build compiler packages / meta packages :

This is only needed for MacOS. On Linux, the compiler packages are already built and available in the `emscripten-forge` channel.
```bash
rattler-build build --recipe recipes/recipes/emscripten_emscripten-wasm32/rattler_recipe.yaml   -c https://repo.mamba.pm/emscripten-forge -c conda-forge -c microsoft -m conda_build_config.yaml
rattler-build build --recipe recipes/recipes/cross-python_emscripten-wasm32/rattler_recipe.yaml -c https://repo.mamba.pm/emscripten-forge -c conda-forge -c microsoft -m conda_build_config.yaml
rattler-build build --recipe recipes/recipes/pytester/rattler_recipe.yaml                       -c https://repo.mamba.pm/emscripten-forge -c conda-forge -c microsoft -m conda_build_config.yaml
```

**3**  Build packages with `rattler-build`:

```bash
rattler-build build --recipe recipes/recipes_emscripten/regex/rattler_recipe.yaml  --target-platform=emscripten-wasm32 -c https://repo.mamba.pm/emscripten-forge -c conda-forge -c microsoft -m conda_build_config.yaml
```


## Outlook

We are working on:
 
 * MambaLite: A wasm compiled version of mamba st. we can **install** `emscripten-forge` packages at wasm-runtime.

## Credits
This project would not have been possible without the pioneering work of the [pyodide](https://pyodide.org/) team.
Many aspects of this project are heavily inspired by the [pyodide](https://pyodide.org/) project. This includes the build scripts and
many of the patches which have been taken from the pyodide packages.
