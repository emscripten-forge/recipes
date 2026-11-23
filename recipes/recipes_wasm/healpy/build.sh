#!/bin/bash

set -eux

# cfitsio and healpix are built from the sdist by setup.py. Remove the shared libz
# so -lz links statically; otherwise the extensions get a DT_NEEDED on libz.so
# that the browser cannot load.
rm -f "${PREFIX}"/lib/libz.so*

export CFLAGS="${CFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS}"
export CXXFLAGS="${CXXFLAGS:-} ${EM_FORGE_SIDE_MODULE_CFLAGS}"
# Reset LDFLAGS: the cross-python activate script sets it to the side-module flags,
# which would make every configure link test a whole-archive side-module link.
# The Python extensions still get -s SIDE_MODULE=1 from LDSHARED.
export LDFLAGS="${EM_FORGE_LDFLAGS_BASE} -L${PREFIX}/lib"

${PYTHON} -m pip install . --no-deps --no-build-isolation ${PIP_ARGS} -vvv
