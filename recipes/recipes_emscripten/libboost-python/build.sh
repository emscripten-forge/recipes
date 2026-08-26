#!/usr/bin/env bash
set -e

# Discover the target Python version (cross-python activated in build env).
PY_VER=$($PYTHON -c "import sys; print('{}.{}'.format(*sys.version_info[:2]))")
echo "Building Boost.Python against target Python ${PY_VER}"

# Tell b2 where the target Python lives. Boost.Build's `using python` needs
# version, driver, include dir, and lib dir. Point at the cross-python's
# static libpython so the produced libboost_python links against the right ABI.
cat > user-config.jam <<EOF
using python : ${PY_VER}
             : ${PREFIX}/bin/python
             : ${PREFIX}/include/python${PY_VER}
             : ${PREFIX}/lib
             ;
EOF

# Bootstrap b2 with the build-platform toolchain, same as boost-cpp does.
# Scope buildable libraries at bootstrap; b2 forbids mixing --with-X and
# --without-X, so we can't restrict at the b2 step directly.
./bootstrap.sh --prefix=${PREFIX} \
    --with-python-version=${PY_VER} \
    --with-libraries=python

# b2's install target walks the whole boost tree and tries to build unrelated
# libs (container, graph, ...) that don't cross-compile cleanly to emscripten.
# We tolerate that failure (|| true) and afterwards verify the artifact we
# actually want — libboost_python — is present. If it isn't, the build failed
# for real and we bail.
./b2 --user-config=user-config.jam \
     variant=release \
     toolset=emscripten \
     link=static \
     threading=single \
     --python-buildid=${PY_VER//./} \
     cxxflags="$SIDE_MODULE_CXXFLAGS -fexceptions -DBOOST_SP_DISABLE_THREADS=1" \
     cflags="$SIDE_MODULE_CFLAGS -fexceptions -DBOOST_SP_DISABLE_THREADS=1" \
     linkflags="-fpic $SIDE_MODULE_LDFLAGS" \
     --layout=system \
     -j"${CPU_COUNT:-2}" \
     --prefix=${PREFIX} \
     install || true

PY_NODOT=${PY_VER//./}
test -f "${PREFIX}/lib/libboost_python${PY_NODOT}-${PY_NODOT}.a" \
  || { echo "libboost_python was not installed — real build failure"; exit 1; }
