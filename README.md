#  Emscripten forge

[![build all](https://github.com/emscripten-forge/recipes/actions/workflows/build_all.yaml/badge.svg?branch=main)](https://github.com/emscripten-forge/recipes/actions/workflows/build_all.yaml)

Build wasm/emscripten packages with conda/mamba/boa.
This repository consists of recipes for conda packages for emscripten.
Most of the recipes have been ported from [pyodide](https://pyodide.org/en/stable/).

While we already have a lot of packages built, this is still a big work in progress.

> **Note**
> The recipes used in this repository follow the [Boa recipe specification](https://boa-build.readthedocs.io/en/latest/recipe_spec.html).

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
Good example recipes are:
 
 * [cffi_example](https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes_emscripten/cffi_example/recipe.yaml) for a `cffi` based package.
 * [xeus-python](https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes_emscripten/xeus-python/recipe.yaml) for a package with a CMake-based build system
 
Once the PR is merged, the package is built and uploaded to https://beta.mamba.pm/channels/emscripten-forge


## Local Builds
We are currently phasing out the use of `boa` in favor of `rattler-build`. Yet we still support `boa` builds
as not all recipes have been ported to `rattler-build` yet.
For each recipe there can be a `rattler_recipe.yaml` and a `recipe.yaml` file. The `rattler_recipe.yaml` file is used for rattler-build and the `recipe.yaml` file is used for boa builds.
Once all recipes have been ported to `rattler-build`, we will remove the `recipe.yaml` files and rename the `rattler_recipe.yaml` files to `recipe.yaml`.



### Local Builds with rattler-build
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

**2b** Build compiler packages / meta packages with for MacOS:

This is only needed for MacOS. On Linux, the compiler packages are already built and available in the `emscripten-forge` channel.
```bash
rattler-build build --recipe recipes/recipes/emscripten_emscripten-wasm32/rattler_recipe.yaml   -c https://repo.mamba.pm/emscripten-forge -c conda-forge -c microsoft -m rattler_conda_build_config.yaml
rattler-build build --recipe recipes/recipes/cross-python_emscripten-wasm32/rattler_recipe.yaml -c https://repo.mamba.pm/emscripten-forge -c conda-forge -c microsoft -m rattler_conda_build_config.yaml
rattler-build build --recipe recipes/recipes/pytester/rattler_recipe.yaml                       -c https://repo.mamba.pm/emscripten-forge -c conda-forge -c microsoft -m rattler_conda_build_config.yaml
```

**3**  Build packages with `rattler-build`:

```bash
rattler-build build  --recipe recipes/recipes_emscripten/regex/rattler_recipe.yaml  --target-platform=emscripten-wasm32 -c https://repo.mamba.pm/emscripten-forge -c conda-forge -c microsoft -m rattler_conda_build_config.yaml
```


### Local Builds with boa (this is deprecated)
Local builds are useful for testing new recipes or debugging build issues, but the setup is a bit more involved and will only work for Linux and MacOS. Local builds on Windows are not yet supported.

 **1** Create a new conda environment from `ci_env.yml` and install playwright in this environment:
 On a Linux system this can be done with:
```bash
micromamba create -n emscripten-forge -f ci_env.yml --yes
micromamba activate emscripten-forge
playwright install
``` 
On a MacOS system, this can be done with:
```bash
micromamba create -n emscripten-forge -f ci_env_macos.yaml --yes
micromamba activate emscripten-forge
python pip install playwright
playwright install
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

**3**  Install a custom version of `boa`
```bash
python -m pip install git+https://github.com/DerThorsten/boa.git@python_api_v2   --no-deps --ignore-installed
```

**4** Add emscripten-forge channel to `.condarc`.
Create a `.condarc` file in your home directory with the following content:
```bash
channels:
  - "https://repo.mamba.pm/emscripten-forge"
  - conda-forge
```

**5a** Build a package (simple version):
To build a package, run this from the root of the repository (replace `regex` with the package you want to build)
```bash
boa build --target-platform=emscripten-wasm32 recipes/recipes_emscripten/regex -m conda_build_config.yaml
```
This should work in principle, but will not run the python tests of the package.

**5b** Build a python package and run tests:
For web assembly packages, we need to run the tests in a browser. This is done via playwright.
We have a custom hacky script which builds the packages via boa and then runs the playwright tests.
To build a package and run the tests, run this from the root of the repository (replace `regex` with the package you want to build) 

```bash
python -m emci build explicit recipes/recipes_emscripten/regex --emscripten-wasm32
```

**6** Building multiple local packages which depend on each other:

If you want to build multiple packages which depend on each other, you have to add the `local-channel` to your `.condarc` file. Since we are building from the `emscripten-forge` environment, we need to modify the `.condarc` file in the `emscripten-forge` environment. You have to add the the `conda-bld` dir
of the `emscripten-forge` environment to the `.condarc` file. This is usually located in `~/micromamba/envs/emscripten-forge/conda-bld` on unix systems.
```bash
channels:
  - /home/your-user-name/micromamba/envs/emscripten-forge/conda-bld
  - "https://repo.mamba.pm/emscripten-forge"
  - conda-forge
```

## Outlook

We are working on:
 
 * Rust integration st. packages with Rust code (ie. `cryptography`) compile to to `wasm32-unknown-emscripten`. This will be relatively simple since  this has already been done by the awesome pyodide team!
 * MambaLite: A wasm compiled version of mamba st. we can **install** `emscripten-forge` packages at wasm-runtime.
 * Binderlite: A JupyterLite / emscripten-forge powered version of Binder.

## Credits
This project would not have been possible without the pioneering work of the [pyodide](https://pyodide.org/) team.
Many aspects of this project are heavily inspired by the [pyodide](https://pyodide.org/) project. This includes the build scripts and
many of the patches which have been taken from the pyodide packages.
