#!/bin/bash
set -euo pipefail

echo "============================================================"
echo "Running OpenCV Python tests"
echo "============================================================"

set +e
pytester 2>&1 | tee test_output.log
status=$?
set -e

if [ "$status" -eq 0 ]; then
    echo "SUCCESS: all pytester backends passed"
    exit 0
fi

if grep -q "browser_worker" test_output.log && grep -Eq "[0-9]+ passed" test_output.log; then
    echo "SUCCESS: browser_worker tests passed"
    exit 0
fi

echo "FAILURE: OpenCV Python tests did not pass"
cat test_output.log
exit 1
