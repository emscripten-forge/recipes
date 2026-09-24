#!/bin/bash
# Build Julia for wasm32-emscripten. The steps follow the ones Keno Fischer
# worked out in https://github.com/Keno/julia-wasm for the JuliaLang/julia
# branch vc/wasm; they are reimplemented here against emscripten 4.0.x and
# emscripten-forge's packages, so none of that repository is used at build
# time:
#
#   1. a *native* 32-bit (i686) Julia, which is only used to generate the
#      system image -- the wasm build has no code generator, it interprets
#   2. the system image, emitted as LLVM bitcode and retargeted to wasm32
#   3. the wasm runtime (libjulia) + the sysimage, linked into julia.js
#
# The i686 bootstrap needs a 32-bit libc, which is what the glibc-i686-linux-gnu
# / gcc-i686-linux-gnu packages provide. Everything on the wasm side uses
# emscripten's own libc and the emscripten-forge builds of gmp, mpfr, pcre2,
# libutf8proc and dsfmt.
set -euxo pipefail

JOBS="${CPU_COUNT:-2}"
TARGET=i686-linux-gnu
JL="${SRC_DIR}/julia"
NATIVE="${JL}/build-native"
WASM="${JL}/build-wasm"
LLVM_VER=6.0.1
LLVM_SRC="${JL}/deps/srccache/llvm-${LLVM_VER}"
LLVM_WASM="${SRC_DIR}/llvm-wasm"
SYSIMG="${SRC_DIR}/sysimg"

# emscripten-forge compiles everything with wasm exception handling and
# wasm longjmp. Julia's tasks are built on Asyncify, which binaryen cannot
# instrument in the presence of EH instructions ("ASYNCIFY=1 is not
# compatible with -fwasm-exceptions"), so this build uses emscripten's
# JS-based setjmp/longjmp instead. The prebuilt C dependencies contain no
# EH/SjLj code, so they link fine either way.
export EMCC_CFLAGS=""
export EM_COMPILER_WRAPPER=""
# ld would otherwise bake $PREFIX/lib (a wasm32 library directory) into every
# i686 binary of the bootstrap build as DT_RPATH.
unset LD_RUN_PATH

# ---------------------------------------------------------------------------
# 0. Everything julia builds for the bootstrap is already in deps/srccache:
#    the recipe downloads each tarball under the name its makefiles look for
#    (deps/tools/git-external.mk extracts with --strip-components 1, so only
#    the file name matters).
# ---------------------------------------------------------------------------
ls -la "${JL}/deps/srccache"

# ---------------------------------------------------------------------------
# 2. Native (i686) bootstrap build. (`make configure` prompts if the build
#    directory is not empty, so nothing may be written into it before this.)
# ---------------------------------------------------------------------------
pushd "${JL}"
make O=build-native configure
popd

# ---------------------------------------------------------------------------
# 2a. errno constants of the *target*.
#
# base/errno_h.jl is generated from the build machine's <errno.h>, but
# emscripten's musl uses the WASI numbering (EAGAIN == 6, not 11). Generate
# the table with emcc so that the system image carries the values the wasm
# runtime will actually return.
# ---------------------------------------------------------------------------
mkdir -p "${SRC_DIR}/errno"
pushd "${SRC_DIR}/errno"
echo '#include <errno.h>' | emcc -E -dM -xc - | sed -n 's/^#define \(E[A-Z0-9]*\) .*/\1/p' | sort -u > names.txt
{
    echo '#include <errno.h>'
    echo '#include <stdio.h>'
    echo 'int main(void) {'
    while read -r name; do
        printf 'printf("const %%s = Int32(%%d)\\n", "%s", %s);\n' "${name}" "${name}"
    done < names.txt
    echo 'return 0; }'
} > gen_errno.c
emcc -O0 gen_errno.c -o gen_errno.js
node gen_errno.js | LC_ALL=C sort > "${NATIVE}/base/errno_h.jl"
head -5 "${NATIVE}/base/errno_h.jl"
popd


cat > "${NATIVE}/Make.user" <<EOF
# 32-bit native build whose only job is to generate the wasm system image.
# julia needs SSE2 on 32-bit x86 (src/atomics.h). -march has to be part of
# CC/CXX here: `override` keeps Make.inc from appending it itself.
override CC := ${TARGET}-gcc -march=pentium4
override CXX := ${TARGET}-g++ -march=pentium4
override AR := ${TARGET}-ar
override RANLIB := ${TARGET}-ranlib
override HOSTCC := ${TARGET}-gcc -march=pentium4
override ARCH := i686
override MARCH := pentium4
override JULIA_CPU_TARGET := pentium4
# pretend to be the wasm target: Sys.ARCH/Sys.KERNEL end up in the image
override BUILD_ARCH_OVERRIDE := wasm
override UNAME_OVERRIDE := Emscripten
override DISABLE_LIBUV := 1
override DISABLE_LIBUNWIND := 1
override JULIA_THREADS := 0
override JULIA_PRECOMPILE := 0
override USE_BINARYBUILDER := 0
override USE_GPL_LIBS := 0
override USE_SYSTEM_BLAS := 1
override USE_SYSTEM_LAPACK := 1
override USE_SYSTEM_LIBGIT2 := 1
override USE_SYSTEM_PATCHELF := 1
override USE_SYSTEM_SUITESPARSE := 1
override USE_SYSTEM_CURL := 1
override PCRE_VER := 10.48
# only the host backend is needed to emit the system image as bitcode
override LLVM_TARGETS := host
override LLVM_EXPERIMENTAL_TARGETS :=
override LLVM_CMAKE_BUILDTYPE := Release
# sources come from the recipe, and are checked by rattler-build
override JLCHECKSUM := true
override NO_GIT := 1
# base/Makefile symlinks the "system" BLAS/LAPACK/libgit2/suitesparse into
# usr/lib/julia with libwhich. None of them are loaded by this bootstrap
# (LinearAlgebra, SparseArrays, LibGit2 and friends are not in the image),
# and there are no i686 builds of them around.
override SYMLINK_SYSTEM_LIBRARIES :=
VERBOSE := 1
EOF

make -C "${NATIVE}" -j"${JOBS}" julia-sysimg-bc
test -f "${NATIVE}/usr/lib/julia/sys.bc"

# ---------------------------------------------------------------------------
# 3. Retarget the system image bitcode to wasm32.
# ---------------------------------------------------------------------------
LLVM_TOOLS="${NATIVE}/usr/tools"
mkdir -p "${SYSIMG}"
pushd "${SYSIMG}"
"${LLVM_TOOLS}/llvm-ar" x "${NATIVE}/usr/lib/julia/sys.bc"
for part in text data; do
    "${LLVM_TOOLS}/llvm-dis" -o "${part}.ll" "${part}.bc"
    python "${RECIPE_DIR}/retarget_sysimg.py" "${part}.ll" "${part}.wasm.ll"
    "${LLVM_TOOLS}/llvm-as" -o "${part}.wasm.bc" "${part}.wasm.ll"
    rm -f "${part}.ll" "${part}.wasm.ll" "${part}.bc"
done
# compile the image ahead of the final link: it is by far the biggest input
emcc -O2 -c text.wasm.bc -o text.o
emcc -O2 -c data.wasm.bc -o data.o
ls -la
popd

# ---------------------------------------------------------------------------
# 4. LLVM Support for wasm.
#
# With JULIACODEGEN=none the runtime still uses llvm::APInt (APInt-C.cpp) and
# a few llvm/ADT containers, so libLLVMSupport has to exist for wasm32. Build
# it from the same (julia-patched) LLVM tree the native build used.
# ---------------------------------------------------------------------------
mkdir -p "${SRC_DIR}/llvm-wasm-build"
pushd "${SRC_DIR}/llvm-wasm-build"
emcmake cmake "${LLVM_SRC}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_TARGETS_TO_BUILD= \
    -DLLVM_HOST_TRIPLE=wasm32-unknown-emscripten \
    -DLLVM_DEFAULT_TARGET_TRIPLE=wasm32-unknown-emscripten \
    -DLLVM_ENABLE_THREADS=OFF -DLLVM_ENABLE_PIC=OFF \
    -DLLVM_ENABLE_ZLIB=OFF -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF -DLLVM_ENABLE_LIBEDIT=OFF \
    -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_TOOLS=OFF -DLLVM_INCLUDE_UTILS=OFF \
    -DLLVM_BUILD_TOOLS=OFF -DLLVM_BUILD_UTILS=OFF
make -j"${JOBS}" LLVMSupport LLVMDemangle
mkdir -p "${LLVM_WASM}/lib" "${LLVM_WASM}/include" "${LLVM_WASM}/bin"
cp lib/libLLVMSupport.a lib/libLLVMDemangle.a "${LLVM_WASM}/lib/"
cp -r "${LLVM_SRC}/include/llvm" "${LLVM_SRC}/include/llvm-c" "${LLVM_WASM}/include/"
cp -r include/llvm/* "${LLVM_WASM}/include/llvm/"
popd
install -m 755 "${RECIPE_DIR}/llvm-config-wasm.sh" "${LLVM_WASM}/bin/llvm-config"

# ---------------------------------------------------------------------------
# 5. wasm runtime build.
# ---------------------------------------------------------------------------
pushd "${JL}"
make O=build-wasm configure
popd

cat > "${WASM}/Make.user" <<EOF
override CC := emcc
override CXX := em++
override AR := emar
override RANLIB := emranlib
override OS := emscripten
override XC_HOST := wasm32-unknown-emscripten
override JULIACODEGEN := none
override DISABLE_LIBUV := 1
override DISABLE_LIBUNWIND := 1
override JULIA_THREADS := 0
override USE_BINARYBUILDER := 0
override USE_GPL_LIBS := 0
override USE_CROSS_FLISP := 1
override HOSTCC := ${TARGET}-gcc
override fPIC :=
# everything below comes from emscripten-forge packages in \$PREFIX
override LOCALBASE := ${PREFIX}
override USE_SYSTEM_LLVM := 1
override USE_LLVM_SHLIB := 0
override USE_SYSTEM_BLAS := 1
override USE_SYSTEM_LAPACK := 1
override USE_SYSTEM_LIBM := 1
override USE_SYSTEM_SUITESPARSE := 1
override USE_SYSTEM_GMP := 1
override USE_SYSTEM_MPFR := 1
override USE_SYSTEM_PCRE := 1
override USE_SYSTEM_DSFMT := 1
override USE_SYSTEM_UTF8PROC := 1
override USE_SYSTEM_PATCHELF := 1
override LIBUTF8PROC := ${PREFIX}/lib/libutf8proc.a
override LLVM_CONFIG := ${LLVM_WASM}/bin/llvm-config
override LLVM_CONFIG_HOST := ${LLVM_WASM}/bin/llvm-config
override CPPFLAGS := -I${PREFIX}/include
override LDFLAGS := -L${PREFIX}/lib
override JLCHECKSUM := true
override NO_GIT := 1
VERBOSE := 1
EOF

# the cross flisp and the utf8proc it links are built for the build machine
cat > "${WASM}/Make.host.user" <<EOF
override CC := ${TARGET}-gcc
override CXX := ${TARGET}-g++
override AR := ${TARGET}-ar
override RANLIB := ${TARGET}-ranlib
override USE_BINARYBUILDER := 0
override DISABLE_LIBUV := 1
override JULIA_THREADS := 0
override JLCHECKSUM := true
EOF

mkdir -p "${WASM}/usr/lib" "${WASM}/usr/bin" "${WASM}/usr/include"
make -C "${WASM}/deps" BUILDING_HOST_TOOLS=1 JLCHECKSUM=true install-utf8proc
make -C "${WASM}" -j"${JOBS}" -C src release

# ---------------------------------------------------------------------------
# 6. Check that both builds agree on the layout of the runtime structures.
#    The image stores them as raw bytes and the generated code bakes in
#    offsets, so a mismatch would show up as silent corruption at run time.
# ---------------------------------------------------------------------------
pushd "${SRC_DIR}"
LAYOUT_FLAGS=(-DJL_DISABLE_LIBUV -DJL_DISABLE_LIBUNWIND -D_GNU_SOURCE -I "${JL}/src" -I "${JL}/src/support"
              -I "${JL}/src/flisp" -I "${JL}/deps/valgrind")
${TARGET}-gcc "${LAYOUT_FLAGS[@]}" -I "${NATIVE}/src" -I "${NATIVE}/usr/include" \
    "${RECIPE_DIR}/check_layouts.c" -o check_layouts_native
emcc "${LAYOUT_FLAGS[@]}" -I "${WASM}/src" -I "${WASM}/usr/include" -I "${PREFIX}/include" \
    "${RECIPE_DIR}/check_layouts.c" -o check_layouts_wasm.js
# "info" lines are reported but not compared (see check_layouts.c)
./check_layouts_native | grep -v '^info' > layout-native.txt
node check_layouts_wasm.js | grep -v '^info' > layout-wasm.txt
diff -u layout-native.txt layout-wasm.txt
popd

# ---------------------------------------------------------------------------
# 7. Link julia.js.
#
# ASYNCIFY provides the stack switching Julia's tasks need; the functions in
# ASYNCIFY_REMOVE are the ones julia-wasm's Makefile blacklisted (they must not unwind,
# and instrumenting them costs a lot of code size).
# ---------------------------------------------------------------------------
ASYNCIFY_REMOVE='["with_tvar","intersect","intersect_sub_datatype","finish_unionall","jl_gc_big_alloc","jl_iintrinsic_1","jl_iintrinsic_2","jl_instantiate_type_in_env","inst_ftypes","jl_","jl_gc_alloc","jl_gc_pool_alloc","jl_gc_collect","__vfprintf_internal","_applyn","gc","fl_load_system_image","eval_abstracttype","eval_primitivetype","eval_structtype","equiv_type","_compile_all_tvar_union","run_finalizer","qsort","fwrite"]'

EXPORTS='["_main","_malloc","_free","_jl_toplevel_eval_in","_jl_initialize","_jl_eval_and_print","_jl_eval_string","_mpfr_set_emin","_jl_call1","_jl_string_ptr","_jl_unbox_bool","_start_task","_jl_get_current_task","_task_ctx_ptr","_jl_get_root_task","_jl_task_wait","_jl_schedule_task","_jl_get_main_module","_jl_get_global","_jl_symbol","_jl_get_ptls_states","_jl_gc_alloc"]'

mkdir -p "${SRC_DIR}/out"
emcc -O2 \
    -DJL_DISABLE_LIBUV \
    -I "${WASM}/src" -I "${JL}/src" -I "${JL}/src/support" -I "${WASM}/usr/include" \
    "${JL}/ui/wasm-support.c" \
    "${SYSIMG}/text.o" "${SYSIMG}/data.o" \
    "${WASM}/usr/lib/libjulia.so.1.3" \
    -L "${LLVM_WASM}/lib" -lLLVMSupport -lLLVMDemangle \
    "${PREFIX}/lib/libpcre2-8.a" "${PREFIX}/lib/libpcre2-16.a" "${PREFIX}/lib/libpcre2-32.a" \
    "${PREFIX}/lib/libgmp.a" "${PREFIX}/lib/libmpfr.a" "${PREFIX}/lib/libdSFMT.a" \
    "${PREFIX}/lib/libutf8proc.a" \
    -sASYNCIFY=1 \
    -sASYNCIFY_STACK_SIZE=1048576 \
    -sASYNCIFY_REMOVE="${ASYNCIFY_REMOVE}" \
    -sALLOW_MEMORY_GROWTH=1 \
    -sINITIAL_MEMORY=268435456 \
    -sMAXIMUM_MEMORY=2147483648 \
    -sSTACK_SIZE=8388608 \
    -sALLOW_TABLE_GROWTH=1 \
    -sEXPORTED_FUNCTIONS="${EXPORTS}" \
    -sEXPORTED_RUNTIME_METHODS='["stringToUTF8","UTF8ToString","lengthBytesUTF8","ccall","cwrap","callMain"]' \
    -sERROR_ON_UNDEFINED_SYMBOLS=0 \
    -sFORCE_FILESYSTEM=1 \
    -lnodefs.js \
    --pre-js "${JL}/src/jsvm-emscripten/boxed.js" \
    --pre-js "${RECIPE_DIR}/node-fs.js" \
    --js-library "${JL}/src/jsvm-emscripten/jscall.js" \
    -o "${SRC_DIR}/out/julia.js"

ls -la "${SRC_DIR}/out"

# ---------------------------------------------------------------------------
# 8. Smoke test and install.
# ---------------------------------------------------------------------------
node "${SRC_DIR}/out/julia.js" -e 'println("julia wasm says ", 1 + 1)'
# the same checks the package test runs, so that a broken build fails here
node "${SRC_DIR}/out/julia.js" "${RECIPE_DIR}/test_julia.jl"

mkdir -p "${PREFIX}/bin" "${PREFIX}/share/julia/website"
install -m 644 "${SRC_DIR}/out/julia.js" "${SRC_DIR}/out/julia.wasm" "${PREFIX}/bin/"

# A browser REPL for the module we just built (recipe/website/index.html).
install -m 644 "${RECIPE_DIR}/website/index.html" "${PREFIX}/share/julia/website/"
ln -sf ../../../bin/julia.js "${PREFIX}/share/julia/website/julia.js"
ln -sf ../../../bin/julia.wasm "${PREFIX}/share/julia/website/julia.wasm"
