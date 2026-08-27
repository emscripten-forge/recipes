#!/usr/bin/env bash
set -euo pipefail

echo "Checking Qt6Core5Compat static archive is well-formed"
MEMBERS=$(emar t "${PREFIX}/lib/libQt6Core5Compat.a")
echo "${MEMBERS}" | head
echo "${MEMBERS}" | grep -q '\.o$' \
    || { echo "libQt6Core5Compat.a has no object members"; exit 1; }

echo "Compiling a QTextCodec hello-world against installed headers/libs"
WORK=$(mktemp -d)
cd "${WORK}"

cat > main.cpp <<'EOF'
#include <QTextCodec>
int main() {
    QTextCodec *c = QTextCodec::codecForName("UTF-8");
    return c ? 0 : 1;
}
EOF

em++ -std=c++17 \
    -I"${PREFIX}/include" \
    -I"${PREFIX}/include/QtCore" \
    -I"${PREFIX}/include/QtCore5Compat" \
    -L"${PREFIX}/lib" \
    main.cpp \
    -lQt6Core5Compat -lQt6Core \
    -lQt6BundledPcre2 -lQt6BundledZLIB \
    -o hello.js

test -f hello.wasm || { echo "hello.wasm not produced"; exit 1; }
echo "Qt6Core5Compat compile-link test OK"
