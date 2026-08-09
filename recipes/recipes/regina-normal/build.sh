#!/bin/bash

export CFLAGS="$CFLAGS -fPIC -O3"
export CXXFLAGS="$CXXFLAGS -fPIC -O3"

sed -i "s/platform_extra_link_args = \['-s'\]/platform_extra_link_args = []/" setup.py

${PYTHON} setup.py package_assemble
${PYTHON} -m pip install . -vv --no-build-isolation
