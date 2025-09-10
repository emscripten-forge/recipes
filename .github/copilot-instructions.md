# Emscripten-forge Recipes

Emscripten-forge is a conda package repository for building packages targeting the `emscripten-wasm32` platform (WebAssembly). The repository contains package recipes and uses `pixi` for environment management and `rattler-build` for package building.


## Add New Recipes

To add new recipes follow these steps:

* check if the recipe needs building or is a noarch recipes. **Do not add noarch recipes**
* check if the recipe is already present in the repository
  * if the recipe already exists, update the recipe as needed
  * else, create a new directory for the recipe under `recipes/recipes_emscripten/`
* add a `recipe.yaml` file with the necessary metadata and build instructions
* include any additional files (e.g., patches, scripts) as needed
* test the recipe using the appropriate testing framework
* the title of the PR that adds a new recipe should be "Add [package-name]"

### Recipe source section

For Python packages, the `url` must follow this format
```yaml
source:
- url: https://pypi.io/packages/source/${{ name[0] }}/${{ name }}/${{ name|replace('-','_') }}-${{ version }}.tar.gz
```

### Recipe build section

For Python packages, include the following
```yaml
build:
  number: 0
  script: ${{ PYTHON }} -m pip install . ${{ PIP_ARGS }}
```

For R packages, include
```yaml
build:
  number: 0
  script: $R CMD INSTALL $R_ARGS .
```

For all other packages, add a `build.sh` script with build instructions


### Recipe test section

For Python packages, create a `test_import_[package].py` file. This test
file should contain at least one import test in the following form
```python
def test_import_[recipe]():
    import [package]
```

And in the recipe.yaml, add the following:
```yaml
tests:
- script: pytester
  files:
    recipe:
    - test_import_[package].py
```

For other packages, add tests to check the package contents in the recipe.yaml
For example:
```yaml
tests:
- package_contents:
    files:
    - include/package.hpp
    - lib/package.a
    - lib/package.so
```

### Recipe extra section

The extra section in recipe.yaml should be this
```yaml
extra:
  recipe-maintainers:
  - Copilot
```

Do not add other recipe maintainers.

## Check if the recipe is working

To build the recipe you worked on with rattler-build with:
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
* if you fail to run these commands, report so
