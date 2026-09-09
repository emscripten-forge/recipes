#!/bin/bash
set -ex

# Get python include path from cross-python
PYTHON_INCLUDE=$(python -c "import sysconfig; print(sysconfig.get_path('include'))")
PYTHON_VERSION=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

./bootstrap.sh --prefix=${PREFIX} --with-python=$(which python) --with-python-version=${PYTHON_VERSION}

# Write a user-config.jam that tells b2 about our cross-compiled python
cat > user-config.jam << EOF
using python : ${PYTHON_VERSION}
  : ${BUILD_PREFIX}/bin/python
  : ${PREFIX}/include/python${PYTHON_VERSION}
  : ${PREFIX}/lib
  ;

using emscripten : : em++ ;
EOF

./b2 variant=release toolset=emscripten link=static threading=single \
  --with-python \
  --user-config=user-config.jam \
  cxxflags="$SIDE_MODULE_CXXFLAGS -fexceptions -DBOOST_SP_DISABLE_THREADS=1 -I${PREFIX}/include/python${PYTHON_VERSION}" \
  cflags="$SIDE_MODULE_CFLAGS -fexceptions -DBOOST_SP_DISABLE_THREADS=1" \
  linkflags="-fpic $SIDE_MODULE_LDFLAGS" \
  --layout=system -j"${PYODIDE_JOBS:-3}" --prefix=${PREFIX} \
  install
