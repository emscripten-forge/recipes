#!/usr/bin/env bash
set -euxo pipefail

DATA_DIR="$PREFIX/share/fricas0-data"
mkdir -p "$DATA_DIR"

cp -a ./* "$DATA_DIR/"