# Adding packages

To add a new package to emscripten-forge, just create a Pull Request in [this repository](https://github.com/emscripten-forge/recipes/pulls).
The recipe format is described in the [rattler-build recipe format](https://github.com/prefix-dev/rattler-build?tab=readme-ov-file#the-recipe-format)


## C/C++ Packages
### CMake

Adding cmake based packages is easy. Usually it is enough to replace the `cmake` command with the `emcmake` command and
`make` with `emmake` (see the [emscripten documentation](https://emscripten.org/docs/compiling/Building-Projects.html#integrating-with-a-build-system) for more details).

To build a shared library with CMake, one needs  flags.
These flags can be put into a `.cmake` file:
```CMake
# overwriteProp.cmake
set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE) # does not need to be global :)
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-s SIDE_MODULE=1")
set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "-s SIDE_MODULE=1")
set(CMAKE_STRIP FALSE)  # used by default in pybind11 on .so modules # only for needed when using pybind11
```

This can be passed to the as command line argument to cmake
```
# CLI
... -DCMAKE_PROJECT_INCLUDE=overwriteProp.cmake
```


**Example recipes**:

* [xeus](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/xeus)
* [xeus-javascript](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/xeus-javascript)
* [sqlitecpp](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/sqlitecpp)

### Configure / Make

Usually it is enough to replace the `./configure` command with the `emconfigure ./configure` (see the [emscripten documentation](https://emscripten.org/docs/compiling/Building-Projects.html#integrating-with-a-build-system) for more details).


## Python Packages

### pip / setuptools

For a simple package, only these requirements are usually necessary:

```yaml
requirements:
  build:
    - python
    - cross-python_${{ target_platform }}
    - ${{ compiler("c") }}
    - pip
  host:
    - python
  run:
    - python
```

**Example recipes**:

* [regex](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/regex)


### meson

For a meson package, the following requirements are usually needed.

```yaml
requirements:
  build:
  - ${{ compiler('cxx') }}
  - cross-python_${{target_platform}}
  - meson-python
  - pip >=24
  host:
  - python
```
Furthermore, an `emscripten.meson.cross` file is necessary to set the correct compiler and flags for cross compilation.

```toml
# binaries section is at the end to be able to append the python binary.

[properties]
needs_exe_wrapper = true
skip_sanity_check = true
longdouble_format = 'IEEE_QUAD_LE' # for numpy

[host_machine]
system = 'emscripten'
cpu_family = 'wasm32'
cpu = 'wasm'
endian = 'little'

[binaries]
exe_wrapper = 'node'
pkgconfig = 'pkg-config'

```

In the build script, we append the python binary to the *.cross* file and pass this *.cross* file to the pip command.

```bash
#!/bin/bash

cp $RECIPE_DIR/emscripten.meson.cross $SRC_DIR
echo "python = '${PYTHON}'" >> $SRC_DIR/emscripten.meson.cross

${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross"
```

**Example recipes**:

* [contourpy](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/contourpy)
* [numpy](https://github.com/emscripten-forge/recipes/tree/main/recipes/recipes_emscripten/numpy)

### rust

Building rust packages with PyO3 / maturin typically works out of the box.

For a maturin / cffi / pyo3 package, the following requirements are usually necessary:

```yaml
requirements:
  build:
  - cross-python_${{ target_platform }}
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

## R Packages

For a simple package, only these requirements are usually necessary:

```yaml
requirements:
  build:
  - cross-r-base_${{ target_platform }}
  - ${{ compiler("c") }}
```

All other R-dependencies need to be in all 3 `requirements` sections (`build`, `host`, and `run`).

There needs to be 2 urls because very frequently the first one is not reachable.

For the tests, we only check that the shared library for the package exists. Eventually we should be able to load the package and do actual tests, but that's not available yet.

**Example recipes**:

* [r-yaml](https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes_emscripten/r-yaml/)

## Rcpp

Some R packages use the [Rcpp](https://cran.r-project.org/web/packages/Rcpp/index.html) package.

```yaml
requirements:
  build:
  - cross-r-base_${{ target_platform }}
  - ${{ compiler("c") }}
  - r-rcpp
  host:
  - r-rcpp
  run:
  - r-rcpp
```


**Example recipes**:

* [r-plyr](https://github.com/emscripten-forge/recipes/blob/main/recipes/recipes_emscripten/r-plyr/)