#!/bin/bash
set -e

echo "========================================"
echo "Running r-arrow test suite"
echo "========================================"

# Run R test script
Rscript test_r_arrow.R

echo ""
echo "========================================"
echo "r-arrow tests completed successfully"
echo "========================================"
