#!/bin/bash
set -euo pipefail

# Patch CMakeLists.txt for Emscripten cross-compilation:
#   1. Enable shared/module libraries (override Emscripten.cmake default)
#   2. Add SIDE_MODULE=1 flag for WASM side module output
#   3. Guard out GNU ld --export-dynamic-symbol flags
python3 "${RECIPE_DIR}/patch_cmake.py"

# The release tarball is not a git checkout, so duckdb's custom build backend
# only accepts it if the expected sdist marker files are present.
echo "v${PKG_VERSION}" > duckdb_packaging/duckdb_version.txt
touch PKG-INFO

# Bypass setuptools_scm version detection. DuckDB's custom version scheme
# removes SETUPTOOLS_SCM_PRETEND_VERSION and only respects OVERRIDE_GIT_DESCRIBE.
# The patched CMakeLists.txt dirties the working tree, causing setuptools_scm to
# see distance=0+dirty which fails.
export OVERRIDE_GIT_DESCRIBE="v${PKG_VERSION}"

# DuckDB-specific CMake flags for emscripten-wasm32 builds:
#   BUILD_EXTENSIONS       - bundle core extensions statically
#   BUILD_SHELL            - no interactive shell in wasm
#   BUILD_UNITTESTS        - skip tests (cannot run in wasm)
#   ENABLE_EXTENSION_AUTO* - disabled (no network in wasm)
#   OVERRIDE_GIT_DESCRIBE  - version override for dirty-tree workaround
#   DUCKDB_EXPLICIT_PLATFORM - bakes platform into binary for PRAGMA platform
#
# We append to CMAKE_ARGS (not SKBUILD_CMAKE_DEFINE) because:
#   1. cross-python already sets CMAKE_ARGS with the Emscripten toolchain file
#   2. SKBUILD_CMAKE_DEFINE splits on ';' which conflicts with the BUILD_EXTENSIONS list
#
# Python::Python (Development.Embed) is not found by CMake's FindPython in the
# emscripten cross-compilation environment because there is no shared libpython.
# We point CMake to the static libpython so pybind11 can link against it.
PY_VER_SHORT=$(${PYTHON} -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
export CMAKE_ARGS="${CMAKE_ARGS:-} \
-DBUILD_EXTENSIONS=core_functions;parquet;json;icu \
-DBUILD_SHELL=OFF \
-DBUILD_UNITTESTS=OFF \
-DENABLE_EXTENSION_AUTOLOADING=OFF \
-DENABLE_EXTENSION_AUTOINSTALL=OFF \
-DOVERRIDE_GIT_DESCRIBE=v${PKG_VERSION} \
-DDUCKDB_EXPLICIT_PLATFORM=emscripten_wasm32 \
-DPython_LIBRARY=${PREFIX}/lib/libpython${PY_VER_SHORT}.a \
-DPython3_LIBRARY=${PREFIX}/lib/libpython${PY_VER_SHORT}.a"

# Ensure LDFLAGS includes SIDE_MODULE=1 for the Emscripten linker.
# The activation script defines EM_FORGE_SIDE_MODULE_LDFLAGS but doesn't set
# it as the default. We must use it so em++ produces a WASM side module (.so
# with dylink section) instead of a static archive.
export LDFLAGS="${EM_FORGE_SIDE_MODULE_LDFLAGS:-${LDFLAGS:-}}"

# Pass a config setting via -C to ensure pip provides a non-None config_settings
# dict to duckdb's build_wheel(). Without this, build_backend.py hits an assertion
# when it tries to add OVERRIDE_GIT_DESCRIBE to config_settings=None.
${PYTHON} -m pip install . ${PIP_ARGS} \
  -C cmake.build-type=Release
