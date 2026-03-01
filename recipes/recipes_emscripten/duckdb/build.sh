#!/bin/bash
set -euo pipefail

export SETUPTOOLS_SCM_PRETEND_VERSION="${PKG_VERSION}"

# DuckDB-specific CMake flags for wasm passed via scikit-build-core config settings
${PYTHON} -m pip install . ${PIP_ARGS} \
  -Ccmake.define.OVERRIDE_GIT_DESCRIBE="v${PKG_VERSION}" \
  -Ccmake.define.BUILD_EXTENSIONS="parquet;json;autocomplete" \
  -Ccmake.define.BUILD_SHELL=OFF \
  -Ccmake.define.BUILD_UNITTESTS=OFF \
  -Ccmake.define.ENABLE_EXTENSION_AUTOLOADING=OFF \
  -Ccmake.define.ENABLE_EXTENSION_AUTOINSTALL=OFF
