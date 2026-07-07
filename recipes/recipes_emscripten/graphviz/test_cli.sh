#!/bin/bash
set -euo pipefail

OUTPUT=$(printf 'digraph G {\n  A -> B;\n}\n' | node "${PREFIX}/bin/dot.js" -Kdot -Tsvg)

if [[ ! "${OUTPUT}" =~ \<svg ]]; then
    echo "dot did not render SVG output"
    echo "${OUTPUT}"
    exit 1
fi

echo "dot rendered SVG output successfully"
echo "${OUTPUT}"
