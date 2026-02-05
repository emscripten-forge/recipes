#!/bin/bash

if [[ "${CONDA_BUILD:-0}" == "1" && "${CONDA_BUILD_STATE}" != "TEST" ]]; then
  unset PYTHONPATH
  if [[ "${_CONDA_BACKUP_PYTHONPATH}" != "" ]]; then
    export PYTHONPATH=${_CONDA_BACKUP_PYTHONPATH}
  fi
fi
