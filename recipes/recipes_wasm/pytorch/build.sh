#!/usr/bin/env bash
set -euxo pipefail

unset DEBUG REL_WITH_DEB_INFO
export CMAKE_GENERATOR="Unix Makefiles"
export MAX_JOBS="${CPU_COUNT}"
export CMAKE_BUILD_PARALLEL_LEVEL="${CPU_COUNT}"
toolchain_args="${CMAKE_ARGS:-}"
python_include="${PREFIX}/include/python${PY_VER}"
numpy_include="${SP_DIR}/numpy/_core/include"
python_soabi="cpython-${PY_VER//./}-${target_platform#emscripten-}-emscripten"
export CFLAGS="${CFLAGS:-} -fPIC -fwasm-exceptions -msimd128 -mno-tail-call -sSUPPORT_LONGJMP=wasm"
export CXXFLAGS="${CXXFLAGS:-} -fPIC -fwasm-exceptions -msimd128 -mno-tail-call -sSUPPORT_LONGJMP=wasm"
export LDFLAGS="${LDFLAGS:-} -O2 -fwasm-exceptions -msimd128 -mno-tail-call -sSUPPORT_LONGJMP=wasm -Wl,-rpath,\$ORIGIN -Wl,-rpath,\$ORIGIN/lib -Wl,-rpath,/lib"
export CMAKE_ARGS="${CMAKE_ARGS:-} \
 -DCMAKE_BUILD_TYPE=Release \
 -DCMAKE_PLATFORM_NO_VERSIONED_SONAME=ON \
 -DPython_EXECUTABLE=${PYTHON} \
 -DPython_INCLUDE_DIR=${python_include} \
 -DPython_NumPy_INCLUDE_DIR=${numpy_include} \
 -DPython_SOABI=${python_soabi} \
 -DPython3_EXECUTABLE=${PYTHON} \
 -DPython3_INCLUDE_DIR=${python_include} \
 -DPython3_NumPy_INCLUDE_DIR=${numpy_include} \
 -DPython3_SOABI=${python_soabi} \
 -DPYTHON_EXECUTABLE=${PYTHON} -DPYTHON_INCLUDE_DIR=${python_include} \
 -DCAFFE2_CUSTOM_PROTOC_EXECUTABLE=${BUILD_PREFIX}/bin/protoc \
 -Dprotobuf_BUILD_PROTOC_BINARIES=OFF -Dprotobuf_BUILD_LIBPROTOC=OFF \
 -DUSE_EIGEN_SPARSE=OFF -DUSE_SYSTEM_EIGEN_INSTALL=OFF \
 -DBLAS=OpenBLAS -DBLAS_FORTRAN_STRLEN_END=ON \
 -DOpenBLAS_INCLUDE_DIR=${PREFIX}/include \
 -DOpenBLAS_LIB=${PREFIX}/lib/libopenblas.so \
 -DOPEN_LAPACK_WORKS=ON -DLAPACK_CGESDD_WORKS=ON \
 -DBUILD_SHARED_LIBS=ON -DBUILD_PYTHON=ON -DBUILD_FUNCTORCH=ON \
 -DBUILD_TEST=OFF -DBUILD_BINARY=OFF -DUSE_NUMPY=ON \
 -DUSE_CUDA=OFF -DUSE_ROCM=OFF -DUSE_XPU=OFF -DUSE_MPS=OFF \
 -DUSE_DISTRIBUTED=OFF -DUSE_TENSORPIPE=OFF -DUSE_GLOO=OFF -DUSE_MPI=OFF \
 -DUSE_OPENMP=OFF -DUSE_MKLDNN=OFF -DUSE_NNPACK=OFF \
 -DUSE_PYTORCH_QNNPACK=OFF -DUSE_XNNPACK=OFF -DUSE_FBGEMM=OFF \
 -DUSE_KINETO=OFF -DUSE_ITT=OFF"

# FindBLAS's no-argument probes do not match the Fortran ABI. The declarations
# are checked by the patch and real GEMM/LAPACK calls in the browser tests.
"${PYTHON}" -m pip install . --no-deps --no-build-isolation -v

bridge_dir="${SP_DIR}/torch/_inductor/wasm"
emcmake cmake ${toolchain_args} -S torch/_inductor/wasm -B build-inductor \
    -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" -DCMAKE_INSTALL_PREFIX="${bridge_dir}"
emmake make -C build-inductor -j"${CPU_COUNT}"
emmake make -C build-inductor install

sysroot="${bridge_dir}/sysroot"
emscripten_root="${BUILD_PREFIX}/opt/emsdk/upstream/emscripten"
mkdir -p "${sysroot}/include" "${sysroot}/lib/clang/23"
cp -a "${emscripten_root}/cache/sysroot/include/." "${sysroot}/include/"
cp -a "${python_include}" "${sysroot}/include/"
cp -a "${PREFIX}/lib/clang/23/include" "${sysroot}/lib/clang/23/"

mkdir -p recipe-licenses
cp "${emscripten_root}/system/lib/libcxx/LICENSE.TXT" recipe-licenses/LLVM.txt
cp "${PREFIX}/include/llvm/Support/LICENSE.TXT" recipe-licenses/LLVM-Support.txt
cp "${emscripten_root}/system/lib/libc/musl/COPYRIGHT" recipe-licenses/musl.txt
cp "${emscripten_root}/LICENSE" recipe-licenses/Emscripten.txt

# Shared C++ libraries/headers are a Python-independent libtorch output.
mkdir -p "${PREFIX}/lib" "${PREFIX}/include" "${PREFIX}/share"
for library in libc10.so libshm.so libtorch.so libtorch_cpu.so; do
    mv "${SP_DIR}/torch/lib/${library}" "${PREFIX}/lib/"
done
cp -a "${SP_DIR}/torch/include/." "${PREFIX}/include/"
cp -a "${SP_DIR}/torch/share/." "${PREFIX}/share/"
rm -rf "${SP_DIR}/torch/include" "${SP_DIR}/torch/share"
