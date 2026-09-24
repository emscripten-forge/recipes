#!/bin/bash
# Minimal llvm-config for the wasm32 build of LLVM 6.0.1's Support library.
#
# With JULIACODEGEN=none julia only needs llvm::APInt and a few ADT headers
# (APInt-C.cpp, runtime_ccall.cpp, processor.cpp), so the wasm side links
# libLLVMSupport/libLLVMDemangle and nothing else. The real llvm-config is a
# native binary of the LLVM build; this stands in for it in the wasm build.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
defs="-D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS"
out=()
for arg in "$@"; do
    case "${arg}" in
        --version)      out+=("6.0.1") ;;
        --includedir)   out+=("${root}/include") ;;
        --libdir)       out+=("${root}/lib") ;;
        --bindir)       out+=("${root}/bin") ;;
        --prefix|--obj-root|--src-root)
                        out+=("${root}") ;;
        --cppflags|--cflags)
                        out+=("-I${root}/include" ${defs}) ;;
        --cxxflags)     out+=("-I${root}/include" "-std=c++11" "-fno-exceptions" "-fno-rtti" ${defs}) ;;
        --ldflags)      out+=("-L${root}/lib") ;;
        --libs|--libfiles)
                        out+=("-lLLVMSupport" "-lLLVMDemangle") ;;
        --host-target)  out+=("wasm32-unknown-emscripten") ;;
        --build-mode)   out+=("Release") ;;
        --assertion-mode) out+=("OFF") ;;
        --shared-mode)  out+=("static") ;;
        --system-libs|--targets-built|--has-rtti) ;;
        -*)             ;;   # unknown option: ignore
        *)              ;;   # component name (support, core, ...): ignore
    esac
done
echo "${out[@]}"
