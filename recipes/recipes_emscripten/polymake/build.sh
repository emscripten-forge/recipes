#!/usr/bin/env bash
set -euxo pipefail

strip_arch() { echo "${1:-}" | sed -E 's/-march=[^ ]+//g; s/-mtune=[^ ]+//g'; }

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig"

# Run configure-time Emscripten probes under Node; these are required dependency checks, not a test suite.
export POLYMAKE_TEST_RUNNER="node"
export POLYMAKE_TEST_SUFFIX=".js"
export POLYMAKE_TEST_LDFLAGS="-sEXIT_RUNTIME=1 -sALLOW_MEMORY_GROWTH=1"

# Native Perl drives configure/xsubpp; the target WASM Perl is only compiled and linked against.
BUILD_PERL="${BUILD_PREFIX}/bin/perl"

EMSCRIPTEN_DIR="$(dirname "$(readlink -f "$(command -v emcc)")")"

TARGET_PERL_ARCHLIB="$(ls -d "${PREFIX}"/lib/perl5/*/core_perl | head -n1)"
TARGET_PERL_CORE="${TARGET_PERL_ARCHLIB}/CORE"
TARGET_PERL_PRIVLIB="${PREFIX}/lib/perl5/core_perl"
TARGET_PERL_CONFIG="${TARGET_PERL_ARCHLIB}/Config_heavy.pl"

target_perl_cfg() { sed -n "s/^$1='\(.*\)'\$/\1/p" "${TARGET_PERL_CONFIG}" | head -n1; }

TARGET_PERL_VERSION="$(target_perl_cfg version)"      
TARGET_PERL_CCFLAGS="$(target_perl_cfg ccflags)"
TARGET_PERL_VERSION_ID="${TARGET_PERL_VERSION//./}"   

# Static Perl has no DynaLoader, so link and bootstrap its XS extension archives explicitly.
POLYMAKE_PERL_STATIC_EXT="$(cd "${TARGET_PERL_ARCHLIB}/auto" && find . -name '*.a' | sed -E 's|^\./||; s|/[^/]+\.a$||' | sort -u | tr '\n' ' ')"
export POLYMAKE_PERL_STATIC_EXT

PERL_EXT_ARCHIVES=()
while IFS= read -r a; do
    PERL_EXT_ARCHIVES+=("$a")
done < <(find "${TARGET_PERL_ARCHLIB}/auto" -name '*.a' | sort)

EM_ARCH_FLAGS="-fwasm-exceptions -sSUPPORT_LONGJMP=wasm"

POLYMAKE_CXXFLAGS="$(strip_arch "${CXXFLAGS:-}") ${EM_ARCH_FLAGS} -I${PREFIX}/include -I${PREFIX}/include/flint -I${PREFIX}/include/cddlib -I${PREFIX}/include/singular"
POLYMAKE_CFLAGS="$(strip_arch "${CFLAGS:-}") ${EM_ARCH_FLAGS} -I${PREFIX}/include"
POLYMAKE_LDFLAGS="-L${PREFIX}/lib ${EM_ARCH_FLAGS}"

# Static dependencies must be named explicitly; the stub also supplies Singular APIs unavailable in WASM.
POLYMAKE_EXTRA_LIBS="${SRC_DIR}/polymake_wasm_stubs.o -lntl -lcddgmp -lmathicgb -lmathic -lmemtailor -lgmpxx -lmpfr -lgmp"

EM_LINK_FLAGS=(
  -O2
  ${EM_ARCH_FLAGS}
  -sALLOW_MEMORY_GROWTH=1
  -sINITIAL_MEMORY=512MB
  -sMAXIMUM_MEMORY=4GB
  -sSTACK_SIZE=32MB
  -sFORCE_FILESYSTEM=1
  -sEXIT_RUNTIME=0
  -sWASM_BIGINT
  -sEXPORTED_RUNTIME_METHODS=callMain,ccall,cwrap,FS,ENV
  -Wl,--allow-multiple-definition
)

emcc -c "${RECIPE_DIR}/polymake_wasm_stubs.c" -o "${SRC_DIR}/polymake_wasm_stubs.o" \
    -DPOLYMAKE_WASM_SINGULAR_DIR='"/polymake/singular"'

./configure \
    PERL="${BUILD_PERL}" \
    CC="emcc" \
    CXX="em++" \
    Arch="wasm32" \
    CFLAGS="${POLYMAKE_CFLAGS}" \
    CXXFLAGS="${POLYMAKE_CXXFLAGS}" \
    LDFLAGS="${POLYMAKE_LDFLAGS}" \
    LIBS="${POLYMAKE_EXTRA_LIBS}" \
    --prefix="${PREFIX}" \
    --without-prereq \
    --without-native \
    --without-openmp \
    --with-gmp="${PREFIX}" \
    --with-mpfr="${PREFIX}" \
    --with-boost="${PREFIX}" \
    --with-permlib=bundled \
    --with-bliss="${PREFIX}" \
    --with-cdd="${PREFIX}" \
    --with-flint="${PREFIX}" \
    --with-lrs="${PREFIX}" \
    --with-libnormaliz="${PREFIX}" \
    --without-nauty \
    --with-ppl="${PREFIX}" \
    --with-singular="${PREFIX}" \
    --without-java \
    --without-javaview \
    --without-polydb \
    --without-scip \
    --without-soplex \
    --without-sympol

# configure used the native Perl toolchain; retarget generated build settings to WASM.
sed -i "s|^AR *=.*|AR = emar|" build/config.ninja

ExtUtils_xsubpp="$("${BUILD_PERL}" -e 'for (@INC) { my $p = "$_/ExtUtils/xsubpp"; if (-f $p) { print $p; last } }')"
if [ ! -f "${ExtUtils_xsubpp}" ]; then
    ExtUtils_xsubpp="$(find "${BUILD_PREFIX}/lib" -type f -name xsubpp 2>/dev/null | head -n1)"
fi

PERLX_CONFIG="$(ls build/perlx/*/*/config.ninja | head -n1)"

cat > "${PERLX_CONFIG}" <<EOF
PERL=${BUILD_PERL}
CXXglueFLAGS=-I${TARGET_PERL_CORE} ${TARGET_PERL_CCFLAGS} -DPerlVersion=${TARGET_PERL_VERSION_ID} -Wno-nonnull -Wno-xor-used-as-pow
LIBperlFLAGS=-L${TARGET_PERL_CORE} -lperl
ExtUtils_xsubpp=${ExtUtils_xsubpp}
ExtUtils_typemap=${TARGET_PERL_PRIVLIB}/ExtUtils/typemap
EOF

ninja_var() { sed -n "s|^ *$1 *= *||p" build/config.ninja | head -n1; }

INSTALL_TOP="$(ninja_var InstallTop)"
INSTALL_ARCH="$(ninja_var InstallArch)"

# A configure rerun would overwrite the target-Perl settings above.
export POLYMAKE_NO_RECONFIGURE=1

export NM="$(em-config LLVM_ROOT)/llvm-nm"

ninja -C build/Opt -j"${CPU_COUNT:-2}" all.corelib
ninja -C build/Opt install

TOP_LIBS="$(ninja_var LIBS)"
BUNDLED_LIBS="$(sed -n 's|^bundled\.[a-z0-9_]*\.LIBS *= *||p' build/config.ninja | tr '\n' ' ')"
BUNDLED_LDFLAGS="$(sed -n 's|^bundled\.[a-z0-9_]*\.LDFLAGS *= *||p' build/config.ninja | tr '\n' ' ')"

TOP_LIBS="$(echo "${TOP_LIBS}" | sed -E 's/(^| )-l(dl|pthread)( |$)/ /g')"

# Collect real application archives for the final fused executable.
APP_ARCHIVES=()
for a in "${INSTALL_ARCH}"/lib/*; do
    case "$(basename "$a")" in
        libpolymake-apps*) continue ;;
    esac
    [ -s "$a" ] || continue
    if [ "$(basename "$a")" = "libpolymake-core.a" ]; then
        CORE_ARCHIVE="$a"
    fi
    APP_ARCHIVES+=("$a")
done

LINK_STAGE="${SRC_DIR}/link-stage"
mkdir -p "${LINK_STAGE}"
for i in "${!APP_ARCHIVES[@]}"; do
    mv "${APP_ARCHIVES[$i]}" "${LINK_STAGE}/"
    APP_ARCHIVES[$i]="${LINK_STAGE}/$(basename "${APP_ARCHIVES[$i]}")"
done

CALLABLE_ARCHIVE=""
for c in "${PREFIX}"/lib/libpolymake.*; do
    [ -f "$c" ] && [ ! -L "$c" ] || continue
    case "$c" in *-apps*) continue ;; esac
    CALLABLE_ARCHIVE="$c"
    break
done

rm -f "${INSTALL_ARCH}/shared"

rm -f "${INSTALL_ARCH}"/lib/*
rm -rf "${INSTALL_ARCH}/perlx"

# Pack polymake rules, Perl libraries, and Singular resources into the WASM filesystem image.
python3 "${EMSCRIPTEN_DIR}/tools/file_packager.py" \
    "${PREFIX}/bin/polymake.data" \
    --preload "${INSTALL_TOP}@/polymake/share" \
    --preload "${INSTALL_ARCH}@/polymake/lib" \
    --preload "${PREFIX}/lib/perl5@/polymake/perl5" \
    --preload "${PREFIX}/share/singular@/polymake/singular" \
    --exclude '*/pod/*' '*.pod' '*/demo/*' '*.a' \
    --js-output="${PREFIX}/bin/polymake.data.js"

# Recreate the target Perl search path inside the mounted WASM filesystem.
WASM_PERL5LIB=""
perl_json_reachable=""
for perl_libdir in "$(target_perl_cfg sitearch)" "$(target_perl_cfg sitelib)" \
                   "${TARGET_PERL_ARCHLIB}" "${TARGET_PERL_PRIVLIB}"; do
    case "${perl_libdir}" in
        "${PREFIX}/lib/perl5/"*) ;;
        *) continue ;;
    esac
    [ -f "${perl_libdir}/JSON.pm" ] && perl_json_reachable=1
    WASM_PERL5LIB="${WASM_PERL5LIB}${WASM_PERL5LIB:+:}/polymake/perl5/${perl_libdir#${PREFIX}/lib/perl5/}"
done

em++ -c "${RECIPE_DIR}/polymake_wasm_main.cc" -o polymake_wasm_main.o \
    -std=c++14 -DPOLYMAKE_DEBUG=0 \
    -DPOLYMAKE_WASM_PERL5LIB="\"${WASM_PERL5LIB}\"" \
    ${POLYMAKE_CXXFLAGS} \
    -I"${PREFIX}/include"

mkdir -p "${PREFIX}/bin"

# Keep all application objects: their static constructors register polymake clients before main().
em++ -o "${PREFIX}/bin/polymake.js" \
    polymake_wasm_main.o \
    -Wl,--whole-archive \
    "${APP_ARCHIVES[@]}" \
    "${CALLABLE_ARCHIVE}" \
    -Wl,--no-whole-archive \
    "${PERL_EXT_ARCHIVES[@]}" \
    "${TARGET_PERL_CORE}/libperl.a" \
    -L"${PREFIX}/lib" \
    ${BUNDLED_LDFLAGS} \
    ${BUNDLED_LIBS} \
    ${TOP_LIBS} \
    "${EM_LINK_FLAGS[@]}"

if [ "${CALLABLE_ARCHIVE}" != "${PREFIX}/lib/libpolymake.a" ]; then
    mv "${CALLABLE_ARCHIVE}" "${PREFIX}/lib/libpolymake.a"
fi
install -Dm644 "${LINK_STAGE}/$(basename "${CORE_ARCHIVE}")" "${PREFIX}/lib/libpolymake-core.a"
find "${PREFIX}/lib" -maxdepth 1 \( -name 'libpolymake.so*' -o -name 'libpolymake-apps*' \) -delete

LICENSE_DIR="${PREFIX}/share/licenses/${PKG_NAME}"
mkdir -p "${LICENSE_DIR}"
install -Dm644 "${SRC_DIR}/COPYING" "${LICENSE_DIR}/COPYING"

cp -a "$SRC_DIR"/web/* "$PREFIX/bin/"
