#!/usr/bin/env bash
set -euxo pipefail

export CMAKE_GENERATOR="Unix Makefiles"
export CMAKE_BUILD_PARALLEL_LEVEL="${CPU_COUNT}"

# Preserve the dylink metadata required to load the Wasm extension.
"${PYTHON}" -m pip install . --no-deps --no-build-isolation -Cinstall.strip=false -v
