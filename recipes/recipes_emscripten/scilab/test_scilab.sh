#!/usr/bin/env bash
# Tests of the package, under node:
#  1. scilab-cli.js (Scilab without JVM): numerics, gateways, files
#  2. scilab.js, the page's program (Scilab with OpenJDK 21), with headless
#     Java (tests/run_headless.js): Java, graphics exported through the
#     Java2D renderer, Xcos
# The windows themselves need a browser: share/scilab-wasm/index.html.
set -euxo pipefail
export HOME="$PWD/home"
mkdir -p "$HOME"
export SCI="$PREFIX/share/scilab"
WASM="$PREFIX/share/scilab-wasm"

node "$WASM/scilab-cli.js" -nb -quit -e "disp(1 + 1)" | tee simple.log
grep -q "2\." simple.log

timeout 1800 node "$WASM/scilab-cli.js" -nb -noatomsautoload -quit -f tests/cli_tests.sce | tee cli.log
grep -q "ALL TESTS PASSED" cli.log

# Java is interpreted (Zero): this one takes a few minutes
timeout 3600 node tests/run_headless.js "$WASM" -nw -nb -noatomsautoload -quit -f tests/java_tests.sce | tee java.log
grep -q "ALL TESTS PASSED" java.log
