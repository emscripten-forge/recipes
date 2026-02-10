#!/bin/bash
set -e

# Note: Don't use side module flags for tests - we need standalone executables
export CXXFLAGS="${CXXFLAGS} -fPIC"

# Function to build and run a test
run_test() {
    local test_name=$1
    local test_dir=$2
    
    echo "=========================================="
    echo "Building test for ${test_name}..."
    echo "=========================================="
    
    mkdir -p build_${test_name}
    cd build_${test_name}
    
    emcmake cmake ../${test_dir} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_FIND_ROOT_PATH=$PREFIX \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DCMAKE_EXE_LINKER_FLAGS="-sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=256MB -sSTACK_SIZE=5MB -sMAIN_MODULE=2 -sERROR_ON_UNDEFINED_SYMBOLS=0 -sFORCE_FILESYSTEM=1 -lnodefs.js"
    
    emmake make
    
    echo "Running test for ${test_name}..."
    node test_${test_name}.js
    
    cd ..
}

# Test each package
if [ -d tests/arrow-cpp ]; then
    run_test "arrow" "tests/arrow-cpp"
fi

if [ -d tests/libarrow-parquet ]; then
    run_test "parquet" "tests/libarrow-parquet"
fi

if [ -d tests/libarrow-compute ]; then
    run_test "compute" "tests/libarrow-compute"
fi

if [ -d tests/libarrow-dataset ]; then
    run_test "dataset" "tests/libarrow-dataset"
fi

if [ -d tests/libarrow-acero ]; then
    run_test "acero" "tests/libarrow-acero"
fi

echo "=========================================="
echo "All tests passed!"
echo "=========================================="
