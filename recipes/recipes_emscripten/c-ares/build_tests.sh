#!/bin/bash
set -exuo pipefail

# c-ares: simple build test to verify the library links correctly
# Just compile a small test program that uses c-ares APIs.

cat > test_cares.c << 'EOF'
#include <ares.h>
#include <stdio.h>

int main() {
    const char *version = ares_version(NULL);
    printf("c-ares version: %s\n", version);
    return 0;
}
EOF

emcc -O2 \
    test_cares.c \
    -I${PREFIX}/include \
    -L${PREFIX}/lib \
    -lcares \
    -o test_cares.js

echo "c-ares test build succeeded"
node test_cares.js
echo "c-ares test run succeeded"
