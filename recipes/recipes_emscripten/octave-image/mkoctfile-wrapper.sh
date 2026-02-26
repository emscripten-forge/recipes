#!/usr/bin/env bash
set -euo pipefail

REAL_MKOCTFILE="$BUILD_PREFIX/bin/mkoctfile.real"

filtered=()
skip_next=0

for arg in "$@"; do
  if [[ $skip_next -eq 1 ]]; then
    skip_next=0
    continue
  fi

  case "$arg" in
    -pthread|-fopenmp|-fstack-protector|-fexceptions)
      ;;
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

filtered+=(-fwasm-exceptions)

exec "$REAL_MKOCTFILE" "${filtered[@]}"