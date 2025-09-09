# Emscripten-forge Recipes

Emscripten-forge is a conda package repository for building packages targeting the `emscripten-wasm32` platform (WebAssembly). The repository contains package recipes and uses `pixi` for environment management and `rattler-build` for package building.


## Add New Recipes

To add new recipes follow the following steps:

* check if the recipe needs building or is a noarch recipes. We **do not add noarch recipes**
* check if the recipe is already present in the repository. If it is, update the existing recipe as needed.
* if not, create a new directory for the recipe under `recipes/recipes_emscripten/`
* add a `recipe.yaml` and file with the necessary metadata and build instructions
* add a `build.sh` script to handle the build process if its more than a one-liner
* include any additional files (e.g., patches, scripts) as needed
* test the recipe using the appropriate testing framework



### Recipe test section
For python packages, tests are defined in recipe.yaml files:
```yaml
tests:
- script: pytester
  files:
    recipe:
    - test_import_[package].py
```

For python packages, most tests are simple import tests. These tests run automatically during package builds. 

For non-python packages, its enough to check if the expected files exist.
For a header only library this might look like:

```yaml
tests:
  - script:
    - if: unix or emscripten
      then:
        - test -d ${PREFIX}/include/xtensor
        - test -f ${PREFIX}/include/xtensor/xarray.hpp
        - test -f ${PREFIX}/share/cmake/xtensor/xtensorConfig.cmake
        - test -f ${PREFIX}/share/cmake/xtensor/xtensorConfigVersion.cmake
```

## Check if the recipe is working

to build the recipe you worked on with rattler-build with:
(where YOUR_RECIPE_NAME is the name of the directory you created):


  rattler-build build \
  --package-format tar-bz2 \
  -c https://repo.prefix.dev/emscripten-forge-dev \
  -c microsoft \
  -c conda-forge \
  --target-platform emscripten-wasm32 \
  --skip-existing none \
  -m variant.yaml \
  --recipe recipes/recipes_emscripten/YOUR_RECIPE_NAME


* this will build the recipe and run tests 
* check the output for any errors or warnings and try to resolve them
* if you fail to run these commands report so