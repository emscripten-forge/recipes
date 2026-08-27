#!/usr/bin/env bash
set -euo pipefail

echo "Checking Qt6Core static archive is well-formed"
MEMBERS=$(emar t "${PREFIX}/lib/libQt6Core.a")
echo "${MEMBERS}" | head
echo "${MEMBERS}" | grep -q '\.o$' \
    || { echo "libQt6Core.a has no object members"; exit 1; }

echo "Compiling a Qt6 hello-world against installed headers/libs"
WORK=$(mktemp -d)
cd "${WORK}"

cat > main.cpp <<'EOF'
#include <QString>
int main() {
    QString s = QStringLiteral("hello");
    return s.isEmpty() ? 1 : 0;
}
EOF

em++ -std=c++17 \
    -I"${PREFIX}/include" \
    -I"${PREFIX}/include/QtCore" \
    -L"${PREFIX}/lib" \
    main.cpp \
    -lQt6Core -lQt6BundledPcre2 -lQt6BundledZLIB \
    -o hello.js

test -f hello.wasm || { echo "hello.wasm not produced"; exit 1; }
echo "Qt6 compile-link test OK"
