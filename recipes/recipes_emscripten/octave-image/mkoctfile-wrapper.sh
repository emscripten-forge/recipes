#!/usr/bin/env bash
set -euo pipefail

REAL_MKOCTFILE="$BUILD_PREFIX/bin/mkoctfile.real"

# Call real mkoctfile and capture output
OUTPUT="$("$REAL_MKOCTFILE" "$@")"
STATUS=$?

if [ $STATUS -ne 0 ]; then
    exit $STATUS
fi

# Remove unwanted threading / parallel flags
FILTERED="$(echo "$OUTPUT" | \
    sed -E \
        -e 's/(^|[[:space:]])-pthread(s)?([[:space:]]|$)/ /g' \
        -e 's/(^|[[:space:]])-fopenmp([[:space:]]|$)/ /g' \
        -e 's/(^|[[:space:]])-openmp([[:space:]]|$)/ /g' \
        -e 's/(^|[[:space:]])-lgomp([[:space:]]|$)/ /g' \
        -e 's/(^|[[:space:]])-liomp5([[:space:]]|$)/ /g' \
        -e 's/(^|[[:space:]])-lomp([[:space:]]|$)/ /g' \
)"

# Normalize whitespace
echo "$FILTERED" | xargs
exit 0
