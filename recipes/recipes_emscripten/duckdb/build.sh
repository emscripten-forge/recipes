#!/bin/bash
set -euo pipefail

export SETUPTOOLS_SCM_PRETEND_VERSION="${PKG_VERSION}"

# DuckDB-specific flags for wasm
export DUCKDB_NO_THREADS=1
export DUCKDB_EXTENSIONS="parquet;json;autocomplete"
export SKIP_EXTENSIONS="jemalloc"

cd tools/pythonpkg
${PYTHON} -m pip install . ${PIP_ARGS}
