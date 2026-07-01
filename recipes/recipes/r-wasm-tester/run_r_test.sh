#!/bin/bash




set -euo pipefail

show_help() {
    cat <<'EOF'
Usage: run_r_test [<test.R>]
       run_r_test --help

Run an R test script in the wasm R environment via Rtester.js.

Arguments:
  <test.R>    Path to one R test script (e.g. ./test-r-bit.R)
              If omitted, runs all .R files in the current directory

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

if [ "$#" -eq 0 ]; then
    found=0
    
    while IFS= read -r script; do
        found=1
        "$0" "$script"
    done < <(find . -maxdepth 1 -type f -name "*.R" | sort)

    if [ "$found" -eq 0 ]; then
        echo "[R-TESTER] Error: no .R files found in current directory" >&2
        exit 1
    fi
    exit 0
fi

if [ "$#" -ne 1 ]; then 
    echo "[R-TESTER] Error: expected zero or one argument (path to an .R file); try --help" >&2
    exit 1
fi

R_SCRIPT="$1"

if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ]; then
    echo "[R-TESTER] Error: PREFIX is not set or does not exist: ${PREFIX:-}" >&2
    exit 1
fi

if [ ! -f "$RTESTER_JS" ]; then
    echo "[R-TESTER] Error: Rtester.js not found: ${RTESTER_JS}" >&2
    exit 1
fi

if [ ! -f "$R_SCRIPT" ]; then
    echo "[R-TESTER] Error: R script not found: ${R_SCRIPT}" >&2
    exit 1
fi

rm -rf $PREFIX/lib/R/
mv $PREFIX/lib/RPY $PREFIX/lib/R

echo "[R-TESTER] Running test script: ${R_SCRIPT}"
exec env PREFIX="$PREFIX" node "$RTESTER_JS" "$R_SCRIPT"
