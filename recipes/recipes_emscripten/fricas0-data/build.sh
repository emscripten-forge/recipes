#!/usr/bin/env bash
set -euxo pipefail

cd "${SRC_DIR}"

ecl -eval '(progn (load "lisp/load-lisp.lisp") (load "lisp/compile-interp.lisp") (quit))'
echo ')lisp (progn (load "lisp/compile-algebra.lisp") (quit))' | ecl -load fricas

find interp -maxdepth 1 -type f -name "*.lisp" -delete
find algebra -maxdepth 1 -type f -name "*.lsp" -delete

DATA_DIR="$PREFIX/share/fricas0-data"
mkdir -p "$DATA_DIR"

cp -a ./* "$DATA_DIR/"