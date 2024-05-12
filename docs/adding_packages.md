# Adding packages

To add a new package to emscripten-forge, just create a Pull Request in this repository.
The recipe format is described in the [rattler-build recipe format](https://github.com/prefix-dev/rattler-build?tab=readme-ov-file#the-recipe-format)


## C/C++ Packages
### CMake

Adding cmake based packages is easy. Usually it is enough to replace the `cmake` command with the `emcmake` command and
`make` with `emmake` (see the [emscripten documentation](https://emscripten.org/docs/compiling/Building-Projects.html#integrating-with-a-build-system) for more details)



**Example recipes**:

* [xeus](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/xeus)
* [xeus-javascript](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/xeus-javascript)
* [sqlitecpp](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/sqlitecpp)

### Configure / Make

Usually it is enough to replace the `./configure` command with the `emconfigure ./configure` (see the [emscripten documentation](https://emscripten.org/docs/compiling/Building-Projects.html#integrating-with-a-build-system) for more details)


## Python Packages

### pip / setuptools
For simple package only these requirements are usually necessary:
```yaml

requirements:
  build:
    - python
    - cross-python_${{target_platform}}
    - ${{ compiler("c") }}
    - pip
  host:
    - python
  run:
    - python
```

**Example recipes**:

* [regex](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/regex)


### rust 
Building rust package with PyO3 / maturin works usually out of the box.

For a maturin / cffi / pyo3 package, the following requirements are usually necessary:
```yaml
requirements:
  build:
  - cross-python_${{target_platform}}
  - cffi == 1.15.1 (# at the time of writing pinning cffi == 1.15.1 is necessary, may change in the future)
  - setuptools-rust
  - rust
  - maturin

  host:
  - python
  # at the time of writing pinning cffi == 1.15.1 is necessary, may change in the future)
  - cffi == 1.15.1 
  run:
  # at the time of writing pinning cffi == 1.15.1 is necessary, may change in the future)
  - cffi == 1.15.1
```

**Example recipes**:

* [cryptography](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/cryptography)
* [pydantic-core](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/cryptography)
* [pycrdt](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/pycrdt)
