#!/usr/bin/env bash
set -euo pipefail

echo "Checking Qt6WebSockets static archive is well-formed"
MEMBERS=$(emar t "${PREFIX}/lib/libQt6WebSockets.a")
echo "${MEMBERS}" | head
echo "${MEMBERS}" | grep -q '\.o$' \
    || { echo "libQt6WebSockets.a has no object members"; exit 1; }

echo "Compile-only check that Qt6WebSockets headers are usable"
WORK=$(mktemp -d)
cd "${WORK}"

cat > main.cpp <<'EOF'
#include <QWebSocket>
int main() {
    QWebSocket ws;
    (void)ws;
    return 0;
}
EOF

em++ -std=c++17 -c \
    -I"${PREFIX}/include" \
    -I"${PREFIX}/include/QtCore" \
    -I"${PREFIX}/include/QtNetwork" \
    -I"${PREFIX}/include/QtWebSockets" \
    main.cpp -o main.o

test -f main.o || { echo "main.o not produced"; exit 1; }
echo "Qt6WebSockets compile test OK"
