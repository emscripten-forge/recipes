
# Conda build config

Similar to conda-forge, we globally pin packages.
This is essentially a list of packages and versions such as

```yaml
# ...
numpy:
  - 1.25.2
occt:
  - '7.5'
openblas:
  - 0.3.*
openexr:
  - 2.5
openjpeg:
  - '2.4'
openmpi:
  - 4
openssl:
  - 1.1.1
openturns:
  - '1.18'
orc:
  - 1.7.2
# ...
```

This list is used to pin the versions of the dependencies in the `recipe.yaml` of recipes.

Therefore, instead of writing

```yaml
requirements:
  host:
    - numpy 1.25.2
  run:
    - numpy 1.25.2
```

we can write

```yaml
requirements:
  host:
    - numpy
  run:
    - numpy

```
Furthermore, this build-config specifies which compiler to use for each platform.
While conda-forge build configuration can be found [here](https://github.com/conda-forge/conda-forge-pinning-feedstock/blob/main/recipe/conda_build_config.yaml),
we **need** to maintain our own [conda-build-config](https://github.com/emscripten-forge/recipes/blob/main/conda_build_config.yaml). In particular, we need to set up the emscripten compiler.

!!! note
    The conda-build-config of emscripten-forge uses the [rattler-recipes format](https://github.com/prefix-dev/rattler-build?tab=readme-ov-file#the-recipe-format)


```yaml
cxx_compiler:
  - if: emscripten
    then:
      - emscripten
  - if: linux
    then:
      - gxx
  - if: osx
    then:
      - clangxx
```