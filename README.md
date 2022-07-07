#  Emscripten forge

Build wasm / emscripten packages with conda/mamba/boa.
This repository consists of recipes for conda packages for emscripten.
Most of the recipes have been ported from [pyodide](https://pyodide.org/en/stable/)

While we already have a lot of packages build, this is still a big work in progress.

## Installing Packages

## Adding Packages

To add a new package to emscripten-forge, just create a PullRequest to this repository.
This PR should add a new folder in the [recipe_emscripten](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten) folder
containing the recipe of your package.
Good example recipes are:
 
 * [ipywidgets](https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes_emscripten/ipywidgets/recipe.yaml) for a `setuptools` based build system
 * [cffi_example](https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes_emscripten/cffi_example/recipe.yaml) for a `cffi` based package.
 * [xeus-python](https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes_emscripten/xeus-python/recipe.yaml) for a package with a CMake-based build system
 
 Once the PR is merged, the package is build and upoaded to 

## Outlook

We are working on:
 
 * Proper Fortan integration st. packages with Fortan code (ie. `scipy`) compile to `wasm32-emscripten-unknown`
 * Rust integration st. packages with Rust code (ie . `cryptography`) compile to to `wasm-32-emscripten-unknown`. This will be relatively simple since  this has already been done by the awesome pyodide team!
 * MambaLite: A wasm compiled version of mamba st. we can **install** `emscripten-forge` packages at wasm-runtime.
 * Binderlite: A JupyterLite / emscripten-forge powered version of Binder

## Credits
This project would not have been possible without the pioneering work of the [pyodide](https://pyodide.org/) Team.
Many aspects of this project are heavyly inspired by the  [pyodide](https://pyodide.org/) project. This includes the build scripts and
many of the patchesm which have been taken from the pyodide packages.
