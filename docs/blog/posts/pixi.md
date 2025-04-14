---
date: 2024-05-10
category:
    - rust
    
authors:
    - derthorsten
---

# Local builds with `pixi`

Setting up a local build environment for emscripten-forge used to be a very complicated process with many dependencies and many steps.
But with the usage  of [pixi](https://pixi.sh/latest/) this has become trivial!

```bash
# this only needs to be done once
pixi run setup

# thats it! packages can now be built
pixi run build-emscripten-wasm32-pkg recipes/recipes_emscripten/regex
```