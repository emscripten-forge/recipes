#!/bin/bash

rm -rf shapely/speedups/_speedups.c
rm -rf shapely/vectorized/_vectorized.c

python -m cython shapely/speedups/_speedups.pyx
python -m cython shapely/vectorized/_vectorized.pyx

export GEOS_DIR=${PREFIX}

${PYTHON} -m pip install --no-deps --ignore-installed .
