#!/usr/bin/env bash
set -euxo pipefail

# (no install -D: this also builds on macOS)
mkdir -p "$PREFIX/bin" "$PREFIX/share/openjdk-tools/runtime"
install -m 755 kit/openjdk21-wasm-link kit/node/openjdk21-java \
               support/node/openjdk8-java support/node/openjdk8-javaws "$PREFIX/bin/"
install -m 644 kit/gen-symbols.sh "$PREFIX/share/openjdk-tools/"
install -m 644 kit/runtime/java_pre.js "$PREFIX/share/openjdk-tools/runtime/"
install -m 755 kit/serve.py "$PREFIX/share/openjdk-tools/"
