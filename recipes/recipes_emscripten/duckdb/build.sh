#!/bin/bash
set -euo pipefail

# The custom build backend rejects SETUPTOOLS_SCM_PRETEND_VERSION.
# Version is determined via OVERRIDE_GIT_DESCRIBE passed to CMake.

# DuckDB-specific CMake flags for wasm via scikit-build-core
# Each define needs its own env var: SKBUILD_CMAKE_DEFINE_<NAME>=<VALUE>
export SKBUILD_CMAKE_DEFINE_OVERRIDE_GIT_DESCRIBE="v${PKG_VERSION}"
export SKBUILD_CMAKE_DEFINE_BUILD_EXTENSIONS="parquet;json;autocomplete"
export SKBUILD_CMAKE_DEFINE_BUILD_SHELL="OFF"
export SKBUILD_CMAKE_DEFINE_BUILD_UNITTESTS="OFF"
export SKBUILD_CMAKE_DEFINE_ENABLE_EXTENSION_AUTOLOADING="OFF"
export SKBUILD_CMAKE_DEFINE_ENABLE_EXTENSION_AUTOINSTALL="OFF"

${PYTHON} -m pip install . ${PIP_ARGS}
