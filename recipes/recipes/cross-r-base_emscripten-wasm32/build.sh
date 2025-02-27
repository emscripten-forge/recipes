#!/bin/bash

set -eux

mkdir -p ${PREFIX}/etc/conda/activate.d
mkdir -p ${PREFIX}/etc/conda/deactivate.d

cp "${RECIPE_DIR}"/activate-cross-r-base.sh ${PREFIX}/etc/conda/activate.d/
cp "${RECIPE_DIR}"/deactivate-cross-r-base.sh ${PREFIX}/etc/conda/deactivate.d/
