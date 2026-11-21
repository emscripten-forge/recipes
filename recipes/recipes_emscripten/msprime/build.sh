#!/usr/bin/env bash
set -eux

# setup.py locates GSL through CONDA_PREFIX (see PathConfigurator)
export CONDA_PREFIX="${PREFIX}"

${PYTHON} -m pip install . ${PIP_ARGS} -vv
