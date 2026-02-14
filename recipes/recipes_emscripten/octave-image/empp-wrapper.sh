#!/usr/bin/env bash
set -euo pipefail

REAL_EMPP="$BUILD_PREFIX/bin/em++"

filtered=()
skip_next=0

for arg in "$@"; do
  if [[ $skip_next -eq 1 ]]; then
    skip_next=0
    continue
  fi

  case "$arg" in
    -march|-mtune)
      skip_next=1
      ;;
    -march=*|-mtune=*|-fno-plt)
      ;;
    -shared)
      filtered+=("-sSIDE_MODULE=1")
      ;;
    *)
      filtered+=("$arg")
      ;;
  esac
done

exec "$REAL_EMPP" "${filtered[@]}"
