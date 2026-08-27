#!/usr/bin/env bash
set -euo pipefail

echo "Checking Qt6WebChannel static archive is well-formed"
MEMBERS=$(emar t "${PREFIX}/lib/libQt6WebChannel.a")
echo "${MEMBERS}" | head
echo "${MEMBERS}" | grep -q '\.o$' \
    || { echo "libQt6WebChannel.a has no object members"; exit 1; }

echo "Compile-only check that Qt6WebChannel headers are usable"
WORK=$(mktemp -d)
cd "${WORK}"

cat > main.cpp <<'EOF'
#include <QWebChannel>
int main() {
    QWebChannel c;
    (void)c;
    return 0;
}
EOF

em++ -std=c++17 -c \
    -I"${PREFIX}/include" \
    -I"${PREFIX}/include/QtCore" \
    -I"${PREFIX}/include/QtWebChannel" \
    main.cpp -o main.o

test -f main.o || { echo "main.o not produced"; exit 1; }
echo "Qt6WebChannel compile test OK"
