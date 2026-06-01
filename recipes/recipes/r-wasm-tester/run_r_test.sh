#!/bin/bash

set -euo pipefail

show_help() {
    cat <<'EOF'
Usage: run_r_test <test.R>
       run_r_test --help

Run an R test script in the wasm R environment via Rtester.js.

Arguments:
  <test.R>    Path to an R test script (e.g. ./test-r-bit.R)

Options:
  -h, --help  Show this help message and exit

Environment:
  PREFIX      Conda environment prefix with r-base (WebAssembly) installed
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTESTER_JS="${SCRIPT_DIR}/Rtester.js"

if [ "$#" -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    show_help
    exit 0
fi

if [ "$#" -ne 1 ]; then
    echo "error: expected exactly one argument (path to an .R file); try --help" >&2
    exit 1
fi

R_SCRIPT="$1"

if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ]; then
    echo "error: PREFIX is not set or does not exist: ${PREFIX:-}" >&2
    exit 1
fi

if [ ! -f "$RTESTER_JS" ]; then
    echo "error: Rtester.js not found: ${RTESTER_JS}" >&2
    exit 1
fi

if [ ! -f "$R_SCRIPT" ]; then
    echo "error: R script not found: ${R_SCRIPT}" >&2
    exit 1
fi

exec env PREFIX="$PREFIX" node "$RTESTER_JS" "$R_SCRIPT"
