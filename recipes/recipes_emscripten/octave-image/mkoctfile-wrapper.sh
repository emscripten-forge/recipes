#!/usr/bin/env bash
set -euo pipefail

REAL="$BUILD_PREFIX/bin/mkoctfile.real"

filter_flags() {
    echo "$1" \
      | sed -E 's/-pthread//g' \
      | sed -E 's/-fopenmp//g' \
      | sed -E 's/-fstack-protector[^ ]*//g' \
      | sed -E 's/-fexceptions//g' \
      | sed -E 's/-march=[^ ]+//g' \
      | sed -E 's/-mtune=[^ ]+//g' \
      | sed -E 's/-s[[:space:]]*USE_PTHREADS=1//g' \
      | sed -E 's/-s[[:space:]]*PTHREAD_POOL_SIZE=[^ ]+//g'
}

# Intercept -p queries
if [[ "${1:-}" == "-p" ]]; then
    VAR="${2:-}"
    RAW="$("$REAL" -p "$VAR")"
    FILTERED="$(filter_flags "$RAW")"

    if [[ "$VAR" == "CXXFLAGS" ]]; then
        FILTERED="$FILTERED -fwasm-exceptions"
    fi

    echo "$FILTERED"
    exit 0
fi

# Normal compile call
filtered_args=()
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
        -sUSE_PTHREADS=1|-sPTHREAD_POOL_SIZE=*)
            ;;
        -shared)
            filtered_args+=("-sSIDE_MODULE=1")
            ;;
        *)
            filtered_args+=("$arg")
            ;;
    esac
done

filtered_args+=(-fwasm-exceptions)

exec "$REAL" "${filtered_args[@]}"
