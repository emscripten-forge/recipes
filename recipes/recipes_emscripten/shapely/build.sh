#!/bin/bash

export GEOS_CONFIG=${PREFIX}/bin/geos-config

{{ PYTHON }} -m pip install . --no-deps