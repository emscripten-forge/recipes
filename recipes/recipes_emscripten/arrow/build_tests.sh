#!/bin/bash
set -e

# Parse command line arguments
PACKAGE_TO_TEST="${1:-all}"

# Valid package names
VALID_PACKAGES=("all" "arrow-cpp" "arrow-cpp-compute" "arrow-cpp-dataset" "arrow-cpp-acero" "arrow-cpp-parquet")

# Show help message
show_help() {
    echo "Usage: $0 [package-name]"
    echo ""
    echo "Build and run tests for Apache Arrow packages."
    echo ""
    echo "Valid package names:"
    for pkg in "${VALID_PACKAGES[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    echo "Default: all"
    echo ""
    echo "Examples:"
    echo "  $0              # Run all tests"
    echo "  $0 arrow-cpp    # Run only arrow-cpp tests"
    exit 0
}

# Handle help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
fi

# Validate package name
is_valid_package() {
    local pkg=$1
    for valid in "${VALID_PACKAGES[@]}"; do
        if [[ "$pkg" == "$valid" ]]; then
            return 0
        fi
    done
    return 1
}

if ! is_valid_package "$PACKAGE_TO_TEST"; then
    echo "Error: Invalid package name: '$PACKAGE_TO_TEST'"
    echo ""
    echo "Valid package names are:"
    for pkg in "${VALID_PACKAGES[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    echo "Run '$0 --help' for more information."
    exit 1
fi

# Note: Don't use side module flags for tests - we need standalone executables
export CXXFLAGS="${CXXFLAGS} -fPIC"

# Track if any tests ran
TESTS_RAN=false

# Function to build and run a test
run_test() {
    local test_name=$1
    local test_dir=$2
    
    echo "=========================================="
    echo "Building test for ${test_name}..."
    echo "=========================================="
    
    mkdir -p build_${test_name}
    cd build_${test_name}

    export LDFLAGS="${LDFLAGS} -sUSE_ZLIB=1 -sFORCE_FILESYSTEM=1 -sALLOW_MEMORY_GROWTH=1 -sEXPORTED_RUNTIME_METHODS=FS,PATH,ERRNO_CODES -sINITIAL_MEMORY=512MB -sSTACK_SIZE=16MB -sMAXIMUM_MEMORY=2GB"
    
    emcmake cmake ../${test_dir} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_FIND_ROOT_PATH=$PREFIX \
      -DCMAKE_PREFIX_PATH=$PREFIX \
            -DZLIB_ROOT=$PREFIX \
            -DZLIB_LIBRARY=$PREFIX/lib/libz.a \
            -DZLIB_INCLUDE_DIR=$PREFIX/include \
            -DBZIP2_LIBRARY=$PREFIX/lib/libbz2.a \
            -DBZIP2_LIBRARIES=$PREFIX/lib/libbz2.a \
            -DBZIP2_INCLUDE_DIR=$PREFIX/include \
            -DBROTLI_ROOT=$PREFIX \
            -DBROTLI_COMMON_LIBRARY=$PREFIX/lib/libbrotlicommon.a \
            -DBROTLI_ENC_LIBRARY=$PREFIX/lib/libbrotlienc.a \
            -DBROTLI_DEC_LIBRARY=$PREFIX/lib/libbrotlidec.a \
            -DBROTLI_INCLUDE_DIR=$PREFIX/include \
            -DZSTD_ROOT=$PREFIX \
            -DZSTD_LIB=$PREFIX/lib/libzstd.a \
            -DZSTD_INCLUDE_DIR=$PREFIX/include \
            -Dthrift_DIR=$PREFIX/lib/cmake/thrift \
    
    emmake make
    
    echo "Running test for ${test_name}..."
    node test_${test_name}.js
    
    cd ..
    
    TESTS_RAN=true
}

# Test each package
if [[ ("$PACKAGE_TO_TEST" == "all" || "$PACKAGE_TO_TEST" == "arrow-cpp") && -d tests/arrow-cpp ]]; then
    run_test "arrow" "tests/arrow-cpp"
fi

if [[ ("$PACKAGE_TO_TEST" == "all" || "$PACKAGE_TO_TEST" == "arrow-cpp-compute") && -d tests/arrow-cpp-compute ]]; then
    run_test "compute" "tests/arrow-cpp-compute"
fi

if [[ ("$PACKAGE_TO_TEST" == "all" || "$PACKAGE_TO_TEST" == "arrow-cpp-dataset") && -d tests/arrow-cpp-dataset ]]; then
    run_test "dataset" "tests/arrow-cpp-dataset"
fi

if [[ ("$PACKAGE_TO_TEST" == "all" || "$PACKAGE_TO_TEST" == "arrow-cpp-acero") && -d tests/arrow-cpp-acero ]]; then
    run_test "acero" "tests/arrow-cpp-acero"
fi

if [[ ("$PACKAGE_TO_TEST" == "all" || "$PACKAGE_TO_TEST" == "arrow-cpp-parquet") && -d tests/arrow-cpp-parquet ]]; then
    run_test "parquet" "tests/arrow-cpp-parquet"
fi

if [[ "$TESTS_RAN" == "true" ]]; then
    echo "=========================================="
    echo "All tests passed!"
    echo "=========================================="
else
    echo "=========================================="
    echo "Warning: No tests were found or executed for package: $PACKAGE_TO_TEST"
    echo "=========================================="
    exit 1
fi
