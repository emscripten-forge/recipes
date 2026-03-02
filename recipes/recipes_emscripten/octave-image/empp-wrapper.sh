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
    # remove arch tuning
    -march|-mtune)
      skip_next=1
      ;;
    -march=*|-mtune=*|-fno-plt)
      ;;

    # remove pthread / threading flags
    -pthread|-pthreads|-fopenmp|-openmp)
      ;;
    -lpthread|-lpthreads|-lgomp|-lomp|-liomp5)
      ;;
    -sUSE_PTHREADS=*|-sPTHREAD*|-sPROXY_TO_PTHREAD*)
      ;;

    # replace shared with side module
    -shared)
      filtered+=("-sSIDE_MODULE=1")
      ;;

    # keep everything else
    *)
      filtered+=("$arg")
      ;;
  esac
done

# add linkable to filteredargs
filtered+=("-sLINKABLE=1")
# -s EXPORT_ALL=1
filtered+=("-sEXPORT_ALL=1")


echo "Filtered arguments: ${filtered[*]}"
echo "Original arguments: $*"
exec "$REAL_EMPP" "${filtered[@]}"
