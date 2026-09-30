#!/usr/bin/env bash
set -euo pipefail

echo "Checking Qt6Core5Compat static archive is well-formed"
MEMBERS=$(emar t "${PREFIX}/lib/libQt6Core5Compat.a")
echo "${MEMBERS}" | head
echo "${MEMBERS}" | grep -q '\.o$' \
    || { echo "libQt6Core5Compat.a has no object members"; exit 1; }

echo "Compile-only check that Qt6Core5Compat headers are usable"
WORK=$(mktemp -d)
cd "${WORK}"

cat > main.cpp <<'EOF'
#include <QTextCodec>
int main() {
    QTextCodec *c = QTextCodec::codecForName("UTF-8");
    return c ? 0 : 1;
}
EOF

em++ -std=c++17 -c \
    -I"${PREFIX}/include" \
    -I"${PREFIX}/include/QtCore" \
    -I"${PREFIX}/include/QtCore5Compat" \
    main.cpp -o main.o

test -f main.o || { echo "main.o not produced"; exit 1; }
echo "Qt6Core5Compat compile test OK"
