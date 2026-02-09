# Emscripten-forge Recipes

Emscripten-forge is a conda package repository for building packages targeting the `emscripten-wasm32` platform (WebAssembly). This repository uses `pixi` for environment management and `rattler-build` for package building.

## Adding New Recipes

**Pre-checks:**
1. Verify the package requires building for emscripten-wasm32 (**do not add noarch recipes**)
2. Search `recipes/recipes_emscripten/` to check if the recipe already exists
   - If exists: update the existing recipe
   - If new: create directory `recipes/recipes_emscripten/[package-name]/`

**Required files:**
- `recipe.yaml` - package metadata and build instructions
- Additional files as needed: patches, `build.sh`, test files

**PR title format:** `Add [package-name]`

## Recipe Structure

### Context Section

Define version and optionally name for reuse:
```yaml
context:
  name: package-name
  version: x.y.z
```

You can also define computed values:
```yaml
context:
  version: 1.87.0
  filename: boost_${{ version | replace('.', '_') }}.tar.bz2
```

### Package Section

Specify package name and version using Jinja2 templates:
```yaml
package:
  name: ${{ name | lower }}  # Apply filters as needed
  version: ${{ version }}
```

### Source Section

**Python packages:**
```yaml
source:
- url: https://pypi.io/packages/source/${{ name[0] }}/${{ name }}/${{ name|replace('-','_') }}-${{ version }}.tar.gz
  sha256: <hash>
```

**GitHub releases:**
```yaml
source:
- url: https://github.com/owner/repo/archive/refs/tags/v${{ version }}.tar.gz
  sha256: <hash>
```

**With patches:**
```yaml
source:
- url: https://pypi.io/packages/source/${{ name[0] }}/${{ name }}/${{ name }}-${{ version }}.tar.gz
  sha256: <hash>
  patches:
  - patches/0001-fix-build.patch
  - patches/0002-disable-threads.patch
```

Always include `sha256` hash for verification.

**Getting SHA256 hash:**
```bash
curl -sL <url> | sha256sum
```

### Build Section

**Python packages:**
```yaml
build:
  number: 0
  script: ${PYTHON} -m pip install . ${PIP_ARGS}
```

**R packages:**
```yaml
build:
  number: 0
  script: $R CMD INSTALL $R_ARGS .
```

**C++ packages (CMake):**
Create `build.sh` using `emcmake` and `emmake`:
```bash
#!/bin/bash
set -e  # Exit on error

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

emcmake cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX
emmake make -C build -j${CPU_COUNT} install
```

**C++ packages (Autoconf):**
```bash
#!/bin/bash
set -e

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

emconfigure ./configure \
  --prefix=$PREFIX \
  --build=$BUILD \
  --host=none \
  --enable-static \
  --disable-shared
emmake make -j${CPU_COUNT}
emmake make install
```

**Rust packages:**
```yaml
build:
  number: 0
  script: ${PYTHON} -m pip install . -vvv

requirements:
  build:
  - ${{ compiler('c') }}
  - ${{ compiler('cxx') }}
  - python
  - cross-python_${{ target_platform }}
  - rust-nightly
  - maturin
  - setuptools-rust
  host:
  - python
  - cffi
```

In `recipe.yaml`:
```yaml
build:
  number: 0
  script: build.sh
```

**Requirements:**
Specify build, host, and run dependencies:
```yaml
requirements:
  build:
    - ${{ compiler('c') }}      # if C code
    - ${{ compiler('cxx') }}    # if C++ code
    - cmake                      # if using CMake
    - cross-python_${{ target_platform }}  # for cross-compilation
  host:
    - python                     # for Python packages
    - pip                        # for Python packages
  run:
    - python                     # runtime dependencies
```

### Test Section

**Python packages:**
Create `test_import_[package].py`:
```python
def test_import_[package]():
    import [package]
    # Add basic functionality test if applicable
```

In `recipe.yaml`:
```yaml
tests:
- script: pytester
  files:
    recipe:
    - test_import_[package].py
```

**C++ packages:**
Create `build_tests.sh`:
```bash
#!/bin/bash
export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

emcmake cmake -S tests -B build_tests
emmake make -C build_tests
node build_tests/test_executable
```

Create `tests/CMakeLists.txt` and test source files. Reference upstream test/example directories for test cases.

In `recipe.yaml`:
```yaml
tests:
- script:
    - build_tests.sh
  requirements:
    build:
    - ${{ compiler("cxx") }}
    - cmake
    - make
  files:
    recipe:
      - build_tests.sh
      - tests/
```

**File existence tests:**
```yaml
tests:
- package_contents:
    lib:
    - libpackage.a
    include:
    - package.hpp
```

### About Section

Provide package metadata:
```yaml
about:
  homepage: https://package-homepage.com
  license: LICENSE-NAME
  license_family: BSD  # Optional: BSD, Apache, MIT, GPL, etc.
  license_file: LICENSE.txt
  summary: Short package description
  description: |
    Longer package description
  documentation: https://package-docs.com
  repository: https://github.com/owner/repo
```

**Multiple licenses:**
```yaml
about:
  license: Apache-2.0 AND BSD-3-Clause AND MIT
  license_file:
  - LICENSE
  - THIRD_PARTY.txt
```

### Extra Section

```yaml
extra:
  recipe-maintainers:
  - Copilot
```

**Note:** Only use `Copilot` as maintainer.

## Building and Testing

Build the recipe with rattler-build:

```bash
rattler-build build \
  --package-format tar-bz2 \
  -c https://repo.prefix.dev/emscripten-forge-4x \
  -c microsoft \
  -c conda-forge \
  --target-platform emscripten-wasm32 \
  --skip-existing none \
  -m variant.yaml \
  --recipe recipes/recipes_emscripten/YOUR_RECIPE_NAME
```

Replace `YOUR_RECIPE_NAME` with the actual recipe directory name.

**Expected outcome:** Build completes successfully and all tests pass.
**On failure:** Analyze errors in output and resolve build/test issues. Report if unable to proceed.

## Updating Recipes

**Version updates:**
1. Update `version` in context section
2. Update `sha256` hash in source section
3. Increment `build: number` if rebuilding same version
4. Test the updated recipe

**Dependency updates:**
- Modify `requirements` section as needed
- Ensure compatibility with emscripten-wasm32 platform

**Patches:**
- Add patch files to recipe directory
- Reference in source section:
  ```yaml
  source:
  - url: ...
    patches:
    - fix-build.patch
  ```

**PR title format:** `Update [package-name] to [version]` or `Fix [package-name]: [description]`

## Common Patterns

**Multiline build scripts:**
```yaml
build:
  script: |
    export CMAKE_ARGS="-DBUILD_TESTING=OFF"
    ${{ PYTHON }} -m pip install . ${{ PIP_ARGS }}
```

**Build script from file:**
```yaml
build:
  script:
    file: build_script.sh
```

**Platform-specific dependencies:**
```yaml
requirements:
  host:
    - if: emscripten_wasm32
      then: boost-cpp
```

**Known build issues:**
- If linking fails, verify `EM_FORGE_SIDE_MODULE_LDFLAGS` is set
- If headers not found, check `$PREFIX/include` is in include path
- For Python extensions, ensure `PYTHON` and `PIP_ARGS` are used
- Use `ninja` instead of `make` for faster builds when available
- Always use `set -e` in build scripts to catch errors early
- Use `-j${CPU_COUNT}` for parallel builds
- Remove `.la` files if present: `find $PREFIX -name '*.la' -delete`

## Quick Reference

**Finding package versions:**
- PyPI: https://pypi.org/project/package-name/#history
- GitHub: Check releases/tags page

**Common build tools:**
- `cmake`, `make`, `ninja` - for C/C++ packages
- `pip` - for Python packages
- `${{ compiler('c') }}`, `${{ compiler('cxx') }}` - for native compilation
- `meson-python` - for Python packages using Meson
- `cython` - for Python C extensions
- `rust-nightly`, `maturin` - for Rust-based Python packages
- `cross-python_${{ target_platform }}` - for cross-compiling Python extensions

**Environment variables:**
- `$PREFIX` - installation prefix
- `$CPU_COUNT` - number of CPU cores
- `$BUILD` - build platform triplet
- `$HOST` - host platform triplet
- `$EM_FORGE_SIDE_MODULE_CFLAGS` - C/C++ flags for emscripten
- `$EM_FORGE_SIDE_MODULE_LDFLAGS` - linker flags for emscripten
- `BUILD_PREFIX` - build environment prefix
- `$PY_VER` - Python version (e.g., 3.10)
