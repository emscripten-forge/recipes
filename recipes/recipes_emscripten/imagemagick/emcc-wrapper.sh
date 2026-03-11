#!/usr/bin/env bash
set -euo pipefail

REAL_EMCC="${BUILD_PREFIX}/opt/emsdk/upstream/bin/emcc"

if [[ -z "$REAL_EMCC" ]]; then
  echo "emcc not found" >&2
  exit 1
fi
echo "\n\n"
echo "=============================================================="
echo "WELCOME TO THE EMCC WRAPPER"
echo "REAL_EMCC: $REAL_EMCC"
echo "=============================================================="

ARGS=()

for arg in "$@"; do
  case "$arg" in
    -force_load)
      ;;
    *)
      if [[ "${SKIP_NEXT:-0}" -eq 1 ]]; then
        SKIP_NEXT=0
      else
        ARGS+=("$arg")
      fi
      ;;
  esac
done

exec "${REAL_EMCC}" "${ARGS[@]}"