#!/usr/bin/env bash
set -euo pipefail

echo "Checking Qt6Svg static archive is well-formed"
MEMBERS=$(emar t "${PREFIX}/lib/libQt6Svg.a")
echo "${MEMBERS}" | head
echo "${MEMBERS}" | grep -q '\.o$' \
    || { echo "libQt6Svg.a has no object members"; exit 1; }

echo "Compiling a QSvgRenderer hello-world against installed headers/libs"
WORK=$(mktemp -d)
cd "${WORK}"

cat > main.cpp <<'EOF'
#include <QSvgRenderer>
#include <QByteArray>
int main() {
    QByteArray svg = "<svg xmlns='http://www.w3.org/2000/svg' width='1' height='1'/>";
    QSvgRenderer r(svg);
    return r.isValid() ? 0 : 1;
}
EOF

em++ -std=c++17 \
    -I"${PREFIX}/include" \
    -I"${PREFIX}/include/QtCore" \
    -I"${PREFIX}/include/QtGui" \
    -I"${PREFIX}/include/QtSvg" \
    -L"${PREFIX}/lib" \
    main.cpp \
    -lQt6Svg -lQt6Gui -lQt6Core \
    -lQt6BundledPcre2 -lQt6BundledZLIB -lQt6BundledFreetype -lQt6BundledHarfbuzz \
    -o hello.js

test -f hello.wasm || { echo "hello.wasm not produced"; exit 1; }
echo "Qt6Svg compile-link test OK"
