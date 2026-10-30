#!/bin/bash
set -euxo pipefail

# run Singular (built for the browser with JSPI) under node on a script
cat > input.sing <<'EOF'
ring r = 0, (x, y, z), dp;
ideal i = x2 - y, y2 - z, z2 - x;
ideal g = std(i);
print(size(g));
print(vdim(g));
poly f = (x + y)^3;
print(f);
print(factorize(x2 - y2));
quit;
EOF

# (under plain node the LIB bundle Singular.data is not preloaded, so
# Singular warns that it cannot open standard.lib; the kernel works without)
node "${PREFIX}/bin/Singular.js" -q --no-rc < input.sing 2>&1 | tee output.txt

# Singular echoes a "> " prompt before each result
# Groebner basis of x^2 - y, y^2 - z, z^2 - x: 3 elements, 8 solutions
grep -E "(^|> )3$" output.txt
grep -E "(^|> )8$" output.txt
grep -F "x3+3x2y+3xy2+y3" output.txt
grep -F "_[2]=x-y" output.txt
grep -F "_[3]=x+y" output.txt
