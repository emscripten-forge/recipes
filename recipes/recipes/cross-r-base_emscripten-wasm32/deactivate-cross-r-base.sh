#!/bin/bash

if [[ "${CONDA_BUILD:-0}" == "1" && "${CONDA_BUILD_STATE}" != "TEST" ]]; then
  unset R
  unset R_ARGS
  unset R_HOME
fi
