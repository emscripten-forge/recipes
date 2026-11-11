#!/bin/bash

################################################################################
# Flang wrapper to compile with flang but link with emcc
################################################################################

set -euo pipefail

FLANG_BIN="${FLANG_BIN:-$BUILD_PREFIX/lib/llvm-toolchain/bin/flang}"
EMCC_BIN="${EMCC_BIN:-emcc}"

# Compile / preprocess / assemble only → flang
for a in "$@"; do
  case "$a" in
    -c|-E|-S|-M|-MM) exec "$FLANG_BIN" "$@" ;;
  esac
done

# Compile any Fortran sources with flang -c, then link with emcc
outdir=$(mktemp -d)
trap 'rm -rf "$outdir"' EXIT

objs=()
link_args=()
i=1
args=("$@")
while (( i <= $# )); do
  a="${args[i-1]}"
  case "$a" in
    *.f|*.F|*.f90|*.F90|*.f95|*.for|*.f77)
      obj="$outdir/$(basename "$a").o"
      "$FLANG_BIN" -c $FFLAGS "$a" -o "$obj"
      objs+=("$obj")
      ;;
    # flang-only; do not pass to emcc
    --target=*)
      ;;
    -fintrinsic-modules-path)
      ((i++))  # skip the path argument
      ;;
    -fintrinsic-modules-path*)
      ;;
    *)
      link_args+=("$a")
      ;;
  esac
  ((i++)) || true
done

exec "$EMCC_BIN" "${objs[@]}" "${link_args[@]}" -lflang_rt.runtime