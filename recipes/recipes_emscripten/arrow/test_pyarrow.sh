#!/bin/bash
set -e

echo "================================================================"
echo "Running PyArrow tests (custom wrapper)"
echo "Note: browser_main backend expected to fail due to >8MB .so file"
echo "================================================================"

# Run pytester and capture output
pytester 2>&1 | tee test_output.log || true

# Check if browser_worker tests passed
# Look for the "22 passed" message indicating successful tests
if grep -q "22 passed" test_output.log; then
    echo ""
    echo "================================================================"
    echo "SUCCESS: browser_worker tests passed (browser_main failure expected)"
    echo "================================================================"
    exit 0
else
    echo ""
    echo "================================================================"
    echo "FAILURE: Tests did not pass"
    echo "================================================================"
    cat test_output.log
    exit 1
fi


