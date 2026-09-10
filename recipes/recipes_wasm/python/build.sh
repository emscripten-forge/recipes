#!/bin/bash
# Flat build script for CPython (emscripten-wasm32 / emscripten-wasm64)
# Consolidates former build.sh + Makefile + Makefile.envs into one script.
# No Makefile is invoked; every step is sequential bash.

set -euxo pipefail

# Specific variables for cross-compilation
if [[ "$target_platform" == "emscripten-wasm32" ]]; then
    export WASM_BITNESS=32
elif [[ "$target_platform" == "emscripten-wasm64" ]]; then
    export WASM_BITNESS=64
else
    echo "Unsupported target_platform: $target_platform"
    exit 1
fi






# ---------------------------------------------------------------------------
# Version / platform
# ---------------------------------------------------------------------------
export PKG_VERSION="${PKG_VERSION:-3.14.3}"
export PY_VERSION="${PY_VERSION:-3.14}"
export PYVERSION="${PYVERSION:-${PKG_VERSION}}"

# Parse major.minor.micro (handles a/b/rc suffixes the same way Makefile.envs did)
version_tmp="${PYVERSION#v}"
version_tmp="${version_tmp//a/ }"
version_tmp="${version_tmp//b/ }"
version_tmp="${version_tmp//r/ }"
# shellcheck disable=SC2086
set -- ${version_tmp//./ }
export PYMAJOR="${1}"
export PYMINOR="${2}"
export PYMICRO="${3:-0}"
export PYSTABLEVERSION="${PYMAJOR}.${PYMINOR}.${PYMICRO}"

export PLATFORM_TRIPLET=wasm${WASM_BITNESS}-emscripten
export CPYTHON_ABI_FLAGS="${CPYTHON_ABI_FLAGS:-}"
export SYSCONFIG_NAME="_sysconfigdata_${CPYTHON_ABI_FLAGS}_emscripten_${PLATFORM_TRIPLET}"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
ROOT="$(pwd)"
export BUILD="${ROOT}/build/${PKG_VERSION}/Python-${PKG_VERSION}"
# Do NOT export INSTALL. Python's Makefile uses $(INSTALL) as the install
# *program* (e.g. /usr/bin/install). Exporting INSTALL=$PREFIX makes
# inclinstall/libinstall try to execute the prefix directory
# ("$PREFIX: is a directory", exit 126).
export SYSCONFIGDATA_DIR="${PREFIX}/sysconfigdata"
LIB="libpython${PYMAJOR}.${PYMINOR}${CPYTHON_ABI_FLAGS}.a"

# Host Python used for cross-build helpers / sysconfig generation
HOSTPYTHONROOT="$(python${PYMAJOR}.${PYMINOR} -c 'import sys; print(sys.prefix)')"
export HOSTPYTHONROOT
export HOSTPYTHON="${HOSTPYTHONROOT}/bin/python${PYMAJOR}.${PYMINOR}"



# ---------------------------------------------------------------------------
# Compiler flags (only what is needed to build CPython itself)
# ---------------------------------------------------------------------------
export OPTFLAGS="${OPTFLAGS:--O2}"
export DBGFLAGS="${DBGFLAGS:--g0}"
export EXTRA_CFLAGS="${EXTRA_CFLAGS:-}"


export EXTRA_CFLAGS="${EXTRA_CFLAGS} -O0 -g3 -gsource-map"


export CFLAGS_BASE="${OPTFLAGS} ${DBGFLAGS} -fPIC -fwasm-exceptions -sSUPPORT_LONGJMP ${EXTRA_CFLAGS}"
export PYTHON_CFLAGS="${CFLAGS_BASE} -DPY_CALL_TRAMPOLINE"

# ---------------------------------------------------------------------------
# Layout prefix dirs
# ---------------------------------------------------------------------------
mkdir -p "${PREFIX}/include"
mkdir -p "${PREFIX}/lib"
mkdir -p "${PREFIX}/bin"
mkdir -p "${PREFIX}/etc/conda"
mkdir -p "${SYSCONFIGDATA_DIR}"
mkdir -p "${BUILD}"

# ---------------------------------------------------------------------------
# Relocate upstream Python source tree into ${BUILD}
# (source is unpacked in the work directory by the recipe)
# ---------------------------------------------------------------------------
mv Makefile.pre.in README.rst aclocal.m4 config.guess config.sub \
   pyconfig.h.in install-sh configure.ac \
   Doc Grammar Include LICENSE Lib Mac Misc Modules Objects \
   PC PCbuild Parser Programs Python Tools configure \
   "${BUILD}/"

# Keep a copy of LICENSE for the recipe / package metadata
cp "${BUILD}/LICENSE" .




# ---------------------------------------------------------------------------
# copy patched emscripten_syscalls.c to the source directory
# make sure $BUILD/Python/emscripten_syscalls.c exists
# ---------------------------------------------------------------------------
if [ ! -f ${BUILD}/Python/emscripten_syscalls.c ]; then
    echo "Error: ${BUILD}/Python/emscripten_syscalls.c does not exist"
    exit 1
fi
cp ${RECIPE_DIR}/patches/emscripten_syscalls.c $BUILD/Python/


# ---------------------------------------------------------------------------
# Host-python symlinks expected by Emscripten tooling
# ---------------------------------------------------------------------------
# The Python build overwrites PYTHON=python.js; emcc/emar still need a real
# host interpreter under the versioned name.
ln -sf "${BUILD_PREFIX}/bin/python${PY_VERSION}" "${BUILD_PREFIX}/bin/python.js"
ln -sf "${BUILD_PREFIX}/bin/python${PY_VERSION}" "${BUILD_PREFIX}/bin/python.mjs"

# Recipe-provided files (patches are already applied by the recipe)
cp "${RECIPE_DIR}/Setup.local" .
cp "${RECIPE_DIR}/adjust_sysconfig.py" .

# ---------------------------------------------------------------------------
# Configure
# ---------------------------------------------------------------------------
cp Setup.local "${BUILD}/Modules/"

(
  cd "${BUILD}"

  # Site overrides for the wasm${WASM_BITNESS}-emscripten config
  echo 'ac_cv_lib_uuid_uuid_generate_time_safe=no' >> ./Tools/wasm/config.site-wasm${WASM_BITNESS}-emscripten
  echo 'have_uuid=no' >> ./Tools/wasm/config.site-wasm${WASM_BITNESS}-emscripten




  ac_cv_header_fcntl_h=yes \
  ac_cv_func_fcntl=yes \
  ac_cv_func_mbstowcs=yes \
  ac_cv_broken_mbstowcs=yes \
  ac_cv_file__dev_ptmx=no \
  ac_cv_file__dev_ptc=no \
  ac_cv_func_memfd_create=no \
  LIBSQLITE3_CFLAGS="-I${PREFIX}/include" \
  LIBSQLITE3_LIBS="-L${PREFIX}/lib -lsqlite3" \
  ZLIB_CFLAGS="-I${PREFIX}/include" \
  ZLIB_LIBS="-L${PREFIX}/lib -lz" \
  BZIP2_CFLAGS="-I${PREFIX}/include" \
  BZIP2_LIBS="-L${PREFIX}/lib -lbz2" \
  CONFIG_SITE=./Tools/wasm/config.site-wasm${WASM_BITNESS}-emscripten \
  READELF=true \
  emconfigure ./configure \
    CFLAGS="${PYTHON_CFLAGS} -I${PREFIX}/include" \
    CPPFLAGS="-I${PREFIX}" \
    LDFLAGS="-L${PREFIX}/lib" \
    PLATFORM_TRIPLET="${PLATFORM_TRIPLET}" \
    --without-pymalloc \
    --disable-shared \
    --disable-ipv6 \
    --enable-big-digits=30 \
    --host=wasm${WASM_BITNESS}-unknown-emscripten \
    --build="$(./config.guess)" \
    --prefix="${PREFIX}" \
    --with-build-python="${BUILD_PREFIX}/bin/python"

)

# ---------------------------------------------------------------------------
# Patch generated Makefile (libinstall deps, extra objects, SIMD again)
# ---------------------------------------------------------------------------
(
  cd "${BUILD}"

  # Clear out libinstall deps (we install what we need explicitly)
  sed -i -e 's/libinstall:.*/libinstall:/' Makefile
)

# ---------------------------------------------------------------------------
# Build static libpython
# ---------------------------------------------------------------------------
(
  cd "${BUILD}"
  sed -i \
    -e 's/^LIBHACL_BLAKE2_SIMD128_OBJS=.*/LIBHACL_BLAKE2_SIMD128_OBJS=/' \
    -e 's/^LIBHACL_BLAKE2_SIMD256_OBJS=.*/LIBHACL_BLAKE2_SIMD256_OBJS=/' \
    Makefile

  make regen-frozen
  env -u INSTALL PREFIX="${PREFIX}" emmake make \
    PYTHON_FOR_BUILD="${HOSTPYTHON}" \
    CROSS_COMPILE=yes \
    "${LIB}" \
    -j"${CPU_COUNT}"
)

# ---------------------------------------------------------------------------
# First sysconfigdata generation (matches former "sysconfigdata" make target)
# ---------------------------------------------------------------------------
(
  cd "${BUILD}"
  _PYTHON_SYSCONFIGDATA_NAME="${SYSCONFIG_NAME}" \
  _PYTHON_PROJECT_BASE="${BUILD}" \
  "${HOSTPYTHON}" -m sysconfig --generate-posix-vars
)
PYBUILDDIR="${BUILD}/$(cat "${BUILD}/pybuilddir.txt")"
ROOT="${ROOT}" PYTHONPATH="${PYBUILDDIR}" python"${PYMAJOR}.${PYMINOR}" adjust_sysconfig.py
mkdir -p "${PREFIX}/lib/python${PYMAJOR}.${PYMINOR}"
cp "${PYBUILDDIR}/${SYSCONFIG_NAME}.py" "${PREFIX}/lib/python${PYMAJOR}.${PYMINOR}/"
cp "${PYBUILDDIR}/${SYSCONFIG_NAME}.py" "${SYSCONFIGDATA_DIR}/"

# ---------------------------------------------------------------------------
# Install headers + lib (inclinstall / libinstall)
# ---------------------------------------------------------------------------
(
  cd "${BUILD}"

  sed -i \
    -e 's/^LIBHACL_BLAKE2_SIMD128_OBJS=.*/LIBHACL_BLAKE2_SIMD128_OBJS=/' \
    -e 's/^LIBHACL_BLAKE2_SIMD256_OBJS=.*/LIBHACL_BLAKE2_SIMD256_OBJS=/' \
    Makefile

  sysconfigpath="$(pwd)/$(cat pybuilddir.txt)/${SYSCONFIG_NAME}.py"
  touch "${LIB}"

  # Python 3.14+ libinstall expects build-details.json (PEP 739). The wasm
  # cross-build path does not produce it automatically; generate it first
  # (same fix as upstream pyodide cpython/Makefile).
  env -u INSTALL PREFIX="${PREFIX}" \
    _PYTHON_SYSCONFIGDATA_NAME="${SYSCONFIG_NAME}" \
    PYTHON_SYSCONFIGDATA_PATH="${sysconfigpath}" \
    PYTHON_FOR_BUILD="${HOSTPYTHON}" \
    emmake make build-details.json

  # Explicitly clear INSTALL so it cannot override Python's install program.
  # Pass PREFIX= for any recipes that consult the environment.
  env -u INSTALL \
  PREFIX="${PREFIX}" \
  _PYTHON_SYSCONFIGDATA_NAME="${SYSCONFIG_NAME}" \
  PYTHON_SYSCONFIGDATA_PATH="${sysconfigpath}" \
  emmake make \
    PYTHON_FOR_BUILD="${HOSTPYTHON}" \
    CROSS_COMPILE=yes \
    inclinstall libinstall "${LIB}" \
    -j"${CPU_COUNT}"

  cp "${LIB}" "${PREFIX}/lib/"
)

# ---------------------------------------------------------------------------
# Final sysconfigdata generation + install (matches former install recipe tail)
# ---------------------------------------------------------------------------
_PYTHON_SYSCONFIGDATA_NAME="${SYSCONFIG_NAME}" \
_PYTHON_PROJECT_BASE="${BUILD}" \
"${HOSTPYTHON}" -m sysconfig --generate-posix-vars

# pybuilddir.txt is written relative to cwd by the host python invocation above
PYBUILDDIR="$(cat pybuilddir.txt)"
PYTHONPATH="${PYBUILDDIR}" python"${PYMAJOR}.${PYMINOR}" adjust_sysconfig.py

mkdir -p "${PREFIX}/lib/python${PYMAJOR}.${PYMINOR}"
cp "${PYBUILDDIR}/${SYSCONFIG_NAME}.py" "${PREFIX}/lib/python${PYMAJOR}.${PYMINOR}/"
mkdir -p "${SYSCONFIGDATA_DIR}"
cp "${PYBUILDDIR}/${SYSCONFIG_NAME}.py" "${SYSCONFIGDATA_DIR}/"

# Historical location used by the package
cp "${SYSCONFIGDATA_DIR}/${SYSCONFIG_NAME}.py" "${PREFIX}/etc/conda/"

rm -rf "${PYBUILDDIR}"
rm -f pybuilddir.txt
# Also clean the one left under BUILD if still present
rm -rf "${BUILD}/$(cat "${BUILD}/pybuilddir.txt" 2>/dev/null || true)" 2>/dev/null || true
rm -f "${BUILD}/pybuilddir.txt" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Collect extra static libraries from extension modules
# ---------------------------------------------------------------------------
for module in "${BUILD}/Modules"/*; do
  [ -d "${module}" ] || continue
  cp "${module}"/*.a "${PREFIX}/lib/" 2>/dev/null || true
done

cp ${BUILD}/Modules/_decimal/libmpdec/libmpdec.a $PREFIX/lib



# ---------------------------------------------------------------------------
# Stub commands (cross build; no native interpreter on the target)
# ---------------------------------------------------------------------------
cat > "${PREFIX}/bin/wheel" <<'EOF'
#!/bin/bash
echo "wheel is not supported on this platform."
exit 1
EOF
chmod +x "${PREFIX}/bin/wheel"

cat > "${PREFIX}/bin/pip" <<'EOF'
#!/bin/bash
echo "pip is not supported on this platform."
exit 1
EOF
chmod +x "${PREFIX}/bin/pip"

cat > "${PREFIX}/bin/python${PY_VERSION}" <<'EOF'
#!/bin/bash
echo "python3 is not supported on this platform."
exit 1
EOF
chmod +x "${PREFIX}/bin/python${PY_VERSION}"

ln -sf "python${PY_VERSION}" "${PREFIX}/bin/python"
ln -sf "python${PY_VERSION}" "${PREFIX}/bin/python3"

echo "Build finished successfully."