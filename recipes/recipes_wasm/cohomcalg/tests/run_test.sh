#!/bin/bash
set -euxo pipefail

# libcohomcalg.a contains the cohomCalg program itself (main.o), so linking
# it gives the command line tool
em++ -o cohomcalg.js -L${PREFIX}/lib -lcohomcalg -sALLOW_MEMORY_GROWTH -sNODERAWFS

node cohomcalg.js --integrated tests/CP2.in | tee out.txt

# integrated mode prints the cohomology dimensions per line bundle
grep -E "0, *0, *1" out.txt
grep -E "6, *0, *0" out.txt
