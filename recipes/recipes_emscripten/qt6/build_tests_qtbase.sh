#!/usr/bin/env bash
set -euo pipefail

echo "Checking Qt6Core static archive is well-formed"
MEMBERS=$(emar t "${PREFIX}/lib/libQt6Core.a")
echo "${MEMBERS}" | head
echo "${MEMBERS}" | grep -q '\.o$' \
    || { echo "libQt6Core.a has no object members"; exit 1; }

echo "Verifying archive members are wasm32 objects"
FIRST_OBJ=$(echo "${MEMBERS}" | grep '\.o$' | head -1)
EXTRACT_DIR=$(mktemp -d)
( cd "${EXTRACT_DIR}" && emar x "${PREFIX}/lib/libQt6Core.a" "${FIRST_OBJ}" )
MAGIC=$(head -c 4 "${EXTRACT_DIR}/${FIRST_OBJ}" | od -An -tx1 | tr -d ' \n')
[ "${MAGIC}" = "0061736d" ] \
    || { echo "expected wasm magic 0061736d, got ${MAGIC}"; exit 1; }

echo "Compile-only check that Qt6Core headers are usable"
WORK=$(mktemp -d)
cd "${WORK}"

cat > main.cpp <<'EOF'
#include <QString>
int main() {
    QString s = QStringLiteral("hello");
    return s.isEmpty() ? 1 : 0;
}
EOF

em++ -std=c++17 -c \
    -I"${PREFIX}/include" \
    -I"${PREFIX}/include/QtCore" \
    main.cpp -o main.o

test -f main.o || { echo "main.o not produced"; exit 1; }
echo "Qt6Core compile test OK"
