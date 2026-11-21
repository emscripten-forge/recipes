#!/bin/bash
set -euo pipefail

: "${GLFW_VERSION:?GLFW_VERSION must be set}"

case "${GLFW_BUILD_SHARED:-}" in
  ON)
    GLFW_LIBRARY_TYPE=SHARED
    GLFW_LIBRARY_FILE=libglfw3.so
    ;;
  OFF)
    GLFW_LIBRARY_TYPE=STATIC
    GLFW_LIBRARY_FILE=libglfw3.a
    ;;
  *)
    echo "GLFW_BUILD_SHARED must be ON or OFF" >&2
    exit 1
    ;;
esac

GLFW_SRC="${SRC_DIR}"
BUILD_DIR="${GLFW_SRC}/build-${GLFW_BUILD_SHARED}"
OBJ_DIR="${BUILD_DIR}/obj"
mkdir -p "${OBJ_DIR}"

GLFW_CXXFLAGS="-I${GLFW_SRC}/external -I${GLFW_SRC}/include ${CXXFLAGS:-} ${EMCC_CFLAGS:-} -O2 -std=c++17 -fPIC"

if [ "${GLFW_BUILD_SHARED}" = "OFF" ]; then
  GLFW_CXXFLAGS="${GLFW_CXXFLAGS} -matomics -mbulk-memory"
fi

objs=()
while IFS= read -r -d '' src; do
  rel="${src#${GLFW_SRC}/src/cpp/}"
  obj="${OBJ_DIR}/${rel//\//_}"
  obj="${obj%.cpp}.o"
  em++ ${GLFW_CXXFLAGS} -c "${src}" -o "${obj}"
  objs+=("${obj}")
done < <(find "${GLFW_SRC}/src/cpp" -name '*.cpp' -print0 | sort -z)

if [ "${GLFW_BUILD_SHARED}" = "ON" ]; then
  em++ ${EM_FORGE_SIDE_MODULE_LDFLAGS:--sSIDE_MODULE=1} "${objs[@]}" -o "${BUILD_DIR}/${GLFW_LIBRARY_FILE}"
else
  emar rcs "${BUILD_DIR}/${GLFW_LIBRARY_FILE}" "${objs[@]}"
fi

mkdir -p "${PREFIX}/include/GLFW" \
         "${PREFIX}/lib/cmake/glfw3" \
         "${PREFIX}/lib/pkgconfig" \
         "${PREFIX}/share/glfw"

cp "${GLFW_SRC}/external/GLFW/glfw3.h" \
   "${GLFW_SRC}/external/GLFW/glfw3native.h" \
   "${PREFIX}/include/GLFW/"
cp "${GLFW_SRC}/include/GLFW/emscripten_glfw3.h" \
   "${GLFW_SRC}/include/GLFW/emscripten_glfw3_version.h" \
   "${PREFIX}/include/GLFW/"
cp "${GLFW_SRC}/src/js/lib_emscripten_glfw3.js" "${PREFIX}/share/glfw/glfw3.js"
cp "${BUILD_DIR}/${GLFW_LIBRARY_FILE}" "${PREFIX}/lib/"

GLFW_API_VERSION="${GLFW_VERSION%.*}"
GLFW_VERSION_TAG="${GLFW_VERSION//./}"
sed \
  -e "s|@GLFW_LIBRARY_TYPE@|${GLFW_LIBRARY_TYPE}|g" \
  -e "s|@GLFW_LIBRARY_FILE@|${GLFW_LIBRARY_FILE}|g" \
  -e "s|@GLFW_API_VERSION@|${GLFW_API_VERSION}|g" \
  -e "s|@PKG_VERSION_TAG@|${GLFW_VERSION_TAG}|g" \
  "${RECIPE_DIR}/glfw3Config.cmake.in" > "${PREFIX}/lib/cmake/glfw3/glfw3Config.cmake"
sed \
  -e "s|@GLFW_API_VERSION@|${GLFW_API_VERSION}|g" \
  "${RECIPE_DIR}/glfw3ConfigVersion.cmake.in" > "${PREFIX}/lib/cmake/glfw3/glfw3ConfigVersion.cmake"

sed \
  -e "s|@GLFW_LIBRARY_FILE@|${GLFW_LIBRARY_FILE}|g" \
  -e "s|@GLFW_API_VERSION@|${GLFW_API_VERSION}|g" \
  -e "s|@PKG_VERSION_TAG@|${GLFW_VERSION_TAG}|g" \
  "${RECIPE_DIR}/glfw3.pc.in" > "${PREFIX}/lib/pkgconfig/glfw3.pc"
