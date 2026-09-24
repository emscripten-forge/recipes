#!/bin/bash
# Builds an i686-linux-gnu toolchain whose C library is glibc built from the
# sourceware release tarball:
#
#   1. binutils        (target i686-linux-gnu)
#   2. gcc, stage 1    (C only, no libc; only used to compile glibc)
#   3. glibc           (installed into $SYSROOT)
#   4. gcc, final      (C and C++, libstdc++, libgcc_s; links against $SYSROOT)
#
# Everything lives below $PREFIX so it can be split into two packages:
#   glibc-i686-linux-gnu : $PREFIX/i686-linux-gnu/sysroot
#   gcc-i686-linux-gnu   : everything else
#
# Programs linked with this gcc get the sysroot's dynamic loader as their
# ELF interpreter and an rpath into the sysroot, so they run on any x86_64
# Linux host (kernel IA-32 emulation is enough, no multilib packages needed).
set -euxo pipefail

TARGET=i686-linux-gnu
SYSROOT="${PREFIX}/${TARGET}/sysroot"
STAGE1="${SRC_DIR}/stage1"
JOBS="${CPU_COUNT:-2}"
BUILD_TRIPLET="$(${SRC_DIR}/gcc/config.guess)"
# read from the source rather than the recipe, so that a version bump to
# the glibc url alone stays consistent
GLIBC_VERSION="$(sed -n 's/^#define VERSION "\(.*\)"$/\1/p' "${SRC_DIR}/glibc/version.h")"

# Host tools (x86_64) are built with the conda-forge compilers from the build
# environment. Do not leak target flags into the i686 builds below.
HOST_CC="${CC}"
HOST_CXX="${CXX}"
HOST_CFLAGS="${CFLAGS:-}"
HOST_CXXFLAGS="${CXXFLAGS:-}"
HOST_LDFLAGS="${LDFLAGS:-}"
# The compiler activation also exports x86_64 binutils and preprocessors
# (CPP, LD, AR, ...). GCC's target libraries and glibc's configure would pick
# them up instead of the i686 tools, so drop them all.
unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS DEBUG_CFLAGS DEBUG_CXXFLAGS DEBUG_CPPFLAGS
unset CPP CXXCPP LD LD_GOLD AS AR NM RANLIB STRIP OBJCOPY OBJDUMP READELF \
      ADDR2LINE ELFEDIT GPROF SIZE STRINGS CXXFILT GCC_AR GCC_NM GCC_RANLIB

mkdir -p "${SYSROOT}/usr/include" "${STAGE1}"

# ---------------------------------------------------------------------------
# Linux UAPI headers. The x86 UAPI headers serve both i386 and x86_64
# (asm/unistd.h dispatches to unistd_32.h when __i386__ is defined).
# ---------------------------------------------------------------------------
# Copy exactly the files of the kernel-headers package: the same directory
# also holds the x86_64 glibc headers of the host compiler's sysroot.
KHDRS_PREFIX="x86_64-conda-linux-gnu/sysroot/usr/include/"
python - "${BUILD_PREFIX}" "${KHDRS_PREFIX}" "${SYSROOT}/usr/include" <<'PYEOF'
import glob, json, os, shutil, sys
build_prefix, rel, dest = sys.argv[1:]
metas = glob.glob(os.path.join(build_prefix, "conda-meta", "kernel-headers_linux-64-*.json"))
assert len(metas) == 1, metas
n = 0
for f in json.load(open(metas[0]))["files"]:
    if not f.startswith(rel):
        continue
    out = os.path.join(dest, f[len(rel):])
    os.makedirs(os.path.dirname(out), exist_ok=True)
    shutil.copy2(os.path.join(build_prefix, f), out)
    n += 1
print("copied", n, "kernel headers")
PYEOF
test -f "${SYSROOT}/usr/include/asm/unistd_32.h"
test ! -e "${SYSROOT}/usr/include/stdio.h"

# ---------------------------------------------------------------------------
# 1. binutils
#
# binutils probes for zstd, debuginfod, msgpack and jansson with pkg-config,
# which searches the *build* environment, while headers are only visible in
# the *host* environment (through -isystem $PREFIX/include). conda-forge's
# compilers pull zstd into the build env, so the probe succeeds and then
# bfd/compress.c fails on a missing <zstd.h>. None of these are wanted in a
# bootstrap toolchain, so ask for none of them rather than depending on what
# the build environment happens to contain.
# ---------------------------------------------------------------------------
mkdir -p build-binutils && pushd build-binutils
CC="${HOST_CC}" CXX="${HOST_CXX}" CFLAGS="${HOST_CFLAGS}" CXXFLAGS="${HOST_CXXFLAGS}" LDFLAGS="${HOST_LDFLAGS}" \
"${SRC_DIR}/binutils/configure" \
    --build="${BUILD_TRIPLET}" --host="${BUILD_TRIPLET}" --target="${TARGET}" \
    --prefix="${PREFIX}" \
    --with-sysroot="${SYSROOT}" \
    --disable-nls --disable-werror --disable-gdb --disable-gdbserver \
    --disable-sim --disable-gprofng --disable-gold --disable-libctf \
    --enable-deterministic-archives --enable-plugins \
    --with-system-zlib \
    --without-zstd --without-debuginfod --without-msgpack --disable-jansson
make -j"${JOBS}"
make install
popd
export PATH="${PREFIX}/bin:${PATH}"

# ---------------------------------------------------------------------------
# 2. gcc stage 1: a C compiler + static libgcc, enough to build glibc.
# ---------------------------------------------------------------------------
GCC_COMMON_ARGS=(
    --build="${BUILD_TRIPLET}" --host="${BUILD_TRIPLET}" --target="${TARGET}"
    --with-sysroot="${SYSROOT}"
    --with-gmp="${PREFIX}" --with-mpfr="${PREFIX}" --with-mpc="${PREFIX}"
    --without-isl --with-system-zlib --without-zstd
    --disable-multilib --disable-nls --disable-bootstrap
    --disable-libsanitizer --disable-libvtv --disable-libssp
    --disable-libquadmath --disable-libgomp --disable-libitm
    --with-arch=i686 --with-tune=generic
)

mkdir -p build-gcc-stage1 && pushd build-gcc-stage1
CC="${HOST_CC}" CXX="${HOST_CXX}" CFLAGS="${HOST_CFLAGS}" CXXFLAGS="${HOST_CXXFLAGS}" LDFLAGS="${HOST_LDFLAGS}" \
"${SRC_DIR}/gcc/configure" \
    "${GCC_COMMON_ARGS[@]}" \
    --prefix="${STAGE1}" \
    --with-as="${PREFIX}/bin/${TARGET}-as" --with-ld="${PREFIX}/bin/${TARGET}-ld" \
    --enable-languages=c \
    --with-newlib --without-headers \
    --disable-shared --disable-threads --disable-libatomic \
    --disable-decimal-float --disable-libstdcxx
make -j"${JOBS}" all-gcc all-target-libgcc
make install-gcc install-target-libgcc
popd
# glibc links its static programs with -lgcc_eh; a --disable-shared libgcc
# keeps the unwinder in libgcc.a.
LIBGCC_DIR="$(dirname "$("${STAGE1}/bin/${TARGET}-gcc" -print-libgcc-file-name)")"
ln -sf libgcc.a "${LIBGCC_DIR}/libgcc_eh.a"

# ---------------------------------------------------------------------------
# 3. glibc
# ---------------------------------------------------------------------------
# rattler-build exports LD_RUN_PATH so that the host tools find their own
# libraries; ld would bake it into glibc's shared objects as DT_RPATH, and a
# dynamic loader that carries an RPATH aborts at startup
# ("elf_get_dynamic_info: Assertion `info[DT_RPATH] == NULL' failed").
(
unset LD_RUN_PATH
mkdir -p build-glibc && pushd build-glibc
cat > configparms <<EOF
slibdir=/lib
rtlddir=/lib
EOF
BUILD_CC="${HOST_CC}" \
CC="${STAGE1}/bin/${TARGET}-gcc" \
CXX=false \
AR="${PREFIX}/bin/${TARGET}-ar" RANLIB="${PREFIX}/bin/${TARGET}-ranlib" \
CFLAGS="-O2 -g0" \
"${SRC_DIR}/glibc/configure" \
    --build="${BUILD_TRIPLET}" --host="${TARGET}" \
    --prefix=/usr \
    --with-headers="${SYSROOT}/usr/include" \
    --with-binutils="${PREFIX}/bin" \
    --enable-kernel=3.2 \
    --disable-werror --disable-profile --disable-nscd --disable-build-nscd \
    --disable-timezone-tools --without-selinux \
    --enable-stack-protector=strong
make -j"${JOBS}"
make install DESTDIR="${SYSROOT}" install_root="${SYSROOT}"
popd
)

# Keep the sysroot lean: headers, libraries, startup files and the loader.
rm -rf "${SYSROOT}/usr/share" "${SYSROOT}/usr/libexec" "${SYSROOT}/usr/bin" \
       "${SYSROOT}/usr/sbin" "${SYSROOT}/sbin" "${SYSROOT}/etc" "${SYSROOT}/var" \
       "${SYSROOT}/usr/lib/gconv" "${SYSROOT}/usr/lib/audit"
test -e "${SYSROOT}/lib/ld-linux.so.2"
test -e "${SYSROOT}/lib/libc.so.6"

# ---------------------------------------------------------------------------
# 4. final gcc (C, C++)
# ---------------------------------------------------------------------------
# Bake the sysroot's loader and library dirs into every program this compiler
# links. The paths contain $PREFIX and are rewritten on installation.
RPATH="${PREFIX}/${TARGET}/lib:${SYSROOT}/lib:${SYSROOT}/usr/lib"
SPECS="%{!static:%{!static-pie:%{!nostdlib:%{!nodefaultlibs:-Wl,-rpath,${RPATH}}}}}"
SPECS="${SPECS} %{!shared:%{!static:%{!static-pie:%{!r:-Wl,--dynamic-linker,${SYSROOT}/lib/ld-linux.so.2}}}}"

mkdir -p build-gcc && pushd build-gcc
CC="${HOST_CC}" CXX="${HOST_CXX}" CFLAGS="${HOST_CFLAGS}" CXXFLAGS="${HOST_CXXFLAGS}" LDFLAGS="${HOST_LDFLAGS}" \
"${SRC_DIR}/gcc/configure" \
    "${GCC_COMMON_ARGS[@]}" \
    --prefix="${PREFIX}" \
    --with-as="${PREFIX}/bin/${TARGET}-as" --with-ld="${PREFIX}/bin/${TARGET}-ld" \
    --enable-languages=c,c++ \
    --enable-shared --enable-threads=posix --enable-__cxa_atexit \
    --enable-libatomic --enable-libstdcxx-time=yes \
    --enable-linker-build-id --enable-gnu-unique-object \
    --with-glibc-version="${GLIBC_VERSION}" \
    --with-specs="${SPECS}"
make -j"${JOBS}" all-gcc all-target-libgcc all-target-libstdc++-v3 all-target-libatomic
make install-gcc install-target-libgcc install-target-libstdc++-v3 install-target-libatomic
popd

rm -rf "${PREFIX}/share/man" "${PREFIX}/share/info" "${PREFIX}/share/gcc-"*
# libtool archives carry absolute build paths and are not needed.
find "${PREFIX}/${TARGET}" "${PREFIX}/lib/gcc" -name '*.la' -delete

# ---------------------------------------------------------------------------
# Smoke tests: C and C++ programs must link and run on this (x86_64) host.
# ---------------------------------------------------------------------------
cd "${SRC_DIR}"
cat > hello.c <<'EOF'
#include <stdio.h>
#include <gnu/libc-version.h>
int main(void) { printf("hello from i686 glibc %s\n", gnu_get_libc_version()); return sizeof(void*) == 4 ? 0 : 1; }
EOF
cat > hello.cpp <<'EOF'
#include <iostream>
#include <string>
#include <vector>
int main() { std::vector<std::string> v{"libstdc++", "on", "i686"}; for (auto &s : v) std::cout << s << ' '; std::cout << std::endl; return 0; }
EOF
"${PREFIX}/bin/${TARGET}-gcc" -O2 hello.c -o hello-c
"${PREFIX}/bin/${TARGET}-g++" -O2 hello.cpp -o hello-cpp
./hello-c
./hello-cpp
