#!/bin/bash

set -euxo pipefail

# Create the pydoc_data package directory in site-packages
mkdir -p $PREFIX/lib/python*/site-packages/pydoc_data

# Copy pydoc_data files from recipe directory
cp -r ${RECIPE_DIR}/pydoc_data/* $PREFIX/lib/python*/site-packages/pydoc_data/