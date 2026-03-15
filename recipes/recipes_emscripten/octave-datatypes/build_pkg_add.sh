#!/usr/bin/env bash
set -euo pipefail

# Configuration
TO_SCAN_DIR=$1
PKGADD="${TO_SCAN_DIR}/PKG_ADD"
PKGDEL="${TO_SCAN_DIR}/PKG_DEL"

# Pre-flight check
if ! command -v wasm-objdump &> /dev/null; then
    echo "Error: wasm-objdump could not be found. Please install wabt."
    exit 1
fi
echo "--------------------------------------------------------------------------------------------"
echo "Scanning directory: ${TO_SCAN_DIR}"
echo "--------------------------------------------------------------------------------------------"
# Clear or create the PKG_ADD and PKG_DEL files
> "$PKGADD"
> "$PKGDEL"

for octfile in "${TO_SCAN_DIR}"/*.oct; do
    # Skip if no .oct files exist
    [ -f "$octfile" ] || continue

    filename=$(basename "$octfile")
    echo " * Inspecting $filename"

    # remove extension to get the base name, e.g. "Gwatershed.oct" -> "Gwatershed"
    base_filename="${filename%.oct}"

    result=$(wasm-objdump -x "$octfile")
    
    # scan results for smth a la  - func[159] <Gwatershed> -> "Gwatershed"
    # only consider functions that start with "G" (for "gateway")
    while IFS= read -r line; do
        if [[ $line =~ func\[[0-9]+\]\ \<(G[^>]+)\> ]]; then
            func_name="${BASH_REMATCH[1]}"

            # if the function starts with "G__" we skip it, as these are usually internal helper functions 
            if [[ $func_name == G__* ]]; then
                # echo "      Skipping internal function: $func_name"
                continue
            fi

            
            # if the function has the name G<base_filename> we skip it
            if [[ $func_name == G${base_filename} ]]; then
                # echo "      Skipping function with same name as oct file: $func_name"
                continue
            fi

            # remove the "G" prefix to get the original function name, e.g. "Gwatershed" -> "watershed"
            original_func_name="${func_name#G}"

            echo "autoload (\"${original_func_name}\", which (\"${base_filename}\"));" >> "$PKGADD"
            echo "autoload (\"${original_func_name}\", which (\"${base_filename}\") "remove");" >> "$PKGDEL"

        fi
    done <<< "$result"



done

echo "--------------------------------------------------------------------------------------------"
echo "PKG_ADD generation complete. Content:"
cat "$PKGADD"

echo "--------------------------------------------------------------------------------------------"
echo "PKG_DEL generation complete. Content:"
cat "$PKGDEL"
echo "--------------------------------------------------------------------------------------------"