---
date: 2024-05-10
category:
    - rust
    
authors:
    - derthorsten
---

# Goodby boa, welcome rattler-build

When emscripten-forge was started, we relied on `https://github.com/mamba-org/boa` which is a [conda-build](https://github.com/conda/conda-build) like tool but 
using more of [mamba](https://github.com/mamba-org/mamba) then [conda](https://github.com/conda/conda).
This was always a bit brittle and we had to maintain a fork of `boa` to make it work with `emscripten-wasm32`.
Testing did not work at all, because test dependencies could only be specified for the `target_platform` and not for the `host_platform`, ie
only for emscripten-wasm32 and not for linux-64 (or any other host platform).
This means there was no sane way to install the "emulators" to run the wasm code on the host platform.
Also the error messages were not very helpful and the code was hard to understand.

But then there came [rattler-build](https://github.com/prefix-dev/rattler-build)
which is a complete rewrite of `boa` / `conda-build` in rust which is faster, hast barley any dependencies and has easy to understand error messages.
And to make it even better, test dependencies can be specified for the host platform and the target platform!
This means we can now install the [pyjs-code-runner](https://github.com/emscripten-forge/pyjs-code-runner) which can be used
to run wasm in a headless browser.

This allows to have a proper test section in the recipe.yaml file like in the [regex](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/regex) recipe:

```yaml

tests:
  - script: pytester
    requirements:
      build:
        - pytester
      run:
        - pytester-run
    files:
      recipe:
        - test_regex.py

```


Today we have removed `boa` support from this repository and are now using only `rattler-build`.