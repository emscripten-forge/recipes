#!/bin/bash

set -eux

if [[ -z "${CONDA_PREFIX:-}" || ! -d "${CONDA_PREFIX}" ]]; then
  echo "CONDA_PREFIX is unset or does not exist: '${CONDA_PREFIX:-}'" >&2
  exit 1
fi

if [[ "${CONDA_PREFIX}" != */test_build_env ]]; then
  echo "Refusing to proceed: CONDA_PREFIX must end with test_build_env, got: ${CONDA_PREFIX}" >&2
  exit 1
fi

export LLVM_DIR="${CONDA_PREFIX}/lib/llvm-toolchain"
if [[ ! -d "${LLVM_DIR}" ]]; then
  echo "LLVM toolchain directory not found: ${LLVM_DIR}" >&2
  exit 1
fi

# Overlay patched LLVM/Flang/LLD into the test build env prefix so RPATH
# ($ORIGIN/../.. -> $CONDA_PREFIX/lib) picks up the patched libLLVM.
cp -a "${LLVM_DIR}/." "${CONDA_PREFIX}/"

export PATH="${CONDA_PREFIX}/bin:${PATH}"

generic-testing
