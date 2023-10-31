#  Emscripten forge


Build wasm/emscripten packages with conda/mamba/boa.
This repository consists of recipes for conda packages for emscripten.
Most of the recipes have been ported from [pyodide](https://pyodide.org/en/stable/).

While we already have a lot of packages built, this is still a big work in progress.

> **Note**
> The recipes used in this repository follow the [Boa recipe specification](https://boa-build.readthedocs.io/en/latest/recipe_spec.html).

## Installing Packages



## Adding Packages

To add a new package to emscripten-forge, just create a Pull Request in this repository.
This PR should add a new folder in the [recipe_emscripten](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten) folder
containing the recipe of your package.
Good example recipes are:
 
 * [cffi_example](https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes_emscripten/cffi_example/recipe.yaml) for a `cffi` based package.
 * [xeus-python](https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes_emscripten/xeus-python/recipe.yaml) for a package with a CMake-based build system
 
Once the PR is merged, the package is built and uploaded to https://beta.mamba.pm/channels/emscripten-forge

## Outlook

We are working on:
 
 * Rust integration st. packages with Rust code (ie. `cryptography`) compile to to `wasm32-unknown-emscripten`. This will be relatively simple since  this has already been done by the awesome pyodide team!
 * MambaLite: A wasm compiled version of mamba st. we can **install** `emscripten-forge` packages at wasm-runtime.
 * Binderlite: A JupyterLite / emscripten-forge powered version of Binder.

## Credits
This project would not have been possible without the pioneering work of the [pyodide](https://pyodide.org/) team.
Many aspects of this project are heavily inspired by the [pyodide](https://pyodide.org/) project. This includes the build scripts and
many of the patches which have been taken from the pyodide packages.
