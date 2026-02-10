#!/usr/bin/env bash
set -euo pipefail

REAL_WASM_LD="$(command -v wasm-ld)"

if [[ -z "$REAL_WASM_LD" ]]; then
  echo "wasm-ld not found" >&2
  exit 1
fi

ARGS=()

for arg in "$@"; do
  case "$arg" in
    --sort-common)
      ;;
    --as-needed)
      ;;
    --disable-new-dtags)
      ;;
    -z)
      SKIP_NEXT=1
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

exec "$REAL_WASM_LD" "${ARGS[@]}"
