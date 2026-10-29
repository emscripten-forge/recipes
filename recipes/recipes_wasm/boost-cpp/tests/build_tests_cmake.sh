set -e
MOD="${1:?usage: build_tests_cmake.sh <base>}"
cd "$(dirname "$0")"

command -v cmake >/dev/null 2>&1 || export PATH="/usr/bin:/bin:$PATH"
emcmake cmake -S . -B "build_${MOD}" -DMOD="${MOD}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH="$PREFIX" -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    >/dev/null
cmake --build "build_${MOD}" -j2 >/dev/null
node "build_${MOD}/test_${MOD}"
