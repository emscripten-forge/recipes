# Local builds


## Local with `pixi`

To build a package locally, the easiest way is to use `pixi` (see [/pixi.sh/latest/#installation](https://pixi.sh/latest/#installation) for installation instructions).
Under the hood, `pixi` uses `rattler-build` to build the package.

```bash
# this only needs to be done once
pixi run setup

# this builds the package
pixi run build-emscripten-wasm32-pkg recipes/recipes_emscripten/regex
```

!!! note
    When using [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/) (WSL), some local builds might fail due to `libatomic` not be available. For cases like this, developers are required a full Linux machine like a virtual machine or cloud server.

## Local builds with `rattler-build`
We recommend using the `pixi` command to build packages locally. However, if you want to use `rattler-build` directly, you can do so with the following steps:


### Create the environment
Create a new conda environment from `ci_env.yml` and install playwright in this environment:
 On a Linux / MacOS this can be done with:
```bash
micromamba create -n emscripten-forge -f ci_env.yml --yes
micromamba activate emscripten-forge
```


**All further steps should be executed in this environment.**
I.e. if you open a new terminal, you have to activate the environment again with `micromamba activate emscripten-forge`.

### Setup emsdk

 We currently need a patched version of emsdk. This is because emscripten had some regressions in the `3.1.45` release wrt. dynamic loading of shared libraries. We use the `./emsdk/setup_emsdk.sh` which takes
 two arguments: the emsdk version and the path where emsdk should be installed.
 In this example we choose `~/emsdk` as the installation path. You have to use version `3.1.45`.

```bash
./emsdk/setup_emsdk.sh 3.1.45 ~/emsdk
```

### Build compiler packages / meta packages:

This is only needed for MacOS. On Linux, the compiler packages are already built and available in the `emscripten-forge` channel.

```bash
rattler-build build --recipe recipes/recipes/emscripten_emscripten-wasm32/recipe.yaml   -c https://repo.mamba.pm/emscripten-forge -c conda-forge -c microsoft -m conda_build_config.yaml
rattler-build build --recipe recipes/recipes/cross-python_emscripten-wasm32/recipe.yaml -c https://repo.mamba.pm/emscripten-forge -c conda-forge -c microsoft -m conda_build_config.yaml
rattler-build build --recipe recipes/recipes/pytester/recipe.yaml                       -c https://repo.mamba.pm/emscripten-forge -c conda-forge -c microsoft -m conda_build_config.yaml
```

### Build packages with `rattler-build`:

```bash
rattler-build build  --recipe recipes/recipes_emscripten/regex/recipe.yaml  --target-platform=emscripten-wasm32 -c https://repo.mamba.pm/emscripten-forge -c conda-forge -c microsoft -m conda_build_config.yaml
```