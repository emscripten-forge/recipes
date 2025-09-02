# Emscripten-forge Recipes

Emscripten-forge is a conda package repository for building packages targeting the `emscripten-wasm32` platform (WebAssembly). The repository contains package recipes and uses `pixi` for environment management and `rattler-build` for package building.


### Repository Structure
```
recipes/
├── recipes/
├── recipes_emscripten/ # this is where the recipes need to go
...
```

### Key Directories and Files
- `recipes/recipes_emscripten/` - All WebAssembly package recipes (283+ packages)


### Package Types and Examples
The repository supports multiple package types:

**Python packages**: zarr, numpy, scipy, matplotlib, pandas, etc.
- Use `cross-python_${{ target_platform }}` build requirement
- Example: `recipes/recipes_emscripten/zarr/`

**C/C++ packages**: boost-cpp, arrow-cpp, opencv, etc.  
- Use `emcmake` instead of `cmake`, `emmake` instead of `make`
- Example: `recipes/recipes_emscripten/boost-cpp/`

**Rust packages**: cryptography, pydantic-core, etc.
- Use `maturin` for PyO3 packages
- Pin `cffi == 1.15.1` during transition period

### Testing
For python packages, tests are defined in recipe.yaml files:
```yaml
tests:
- script: pytester
  files:
    recipe:
    - test_import_[package].py
```

For python packages, most tests are simple import tests. Tests run automatically during package builds.
