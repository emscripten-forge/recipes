#!/usr/bin/env python3
"""
Patch duckdb-python/CMakeLists.txt for Emscripten cross-compilation:

1. Enable shared/module library support (Emscripten.cmake disables it,
   causing pybind11_add_module to produce a static archive instead of a
   WASM side module).
2. Add -sSIDE_MODULE=1 link flag so em++ outputs a proper WASM side module
   with a dylink section that the Emscripten runtime can load at runtime.
3. Guard out GNU ld --export-dynamic-symbol flags that wasm-ld doesn't
   support (symbol exports are handled by SIDE_MODULE linking instead).
"""
import pathlib
import sys

cmake = pathlib.Path("CMakeLists.txt")
text = cmake.read_text()
patches_applied = 0

# ---------- Patch 1: Enable shared library support for Emscripten ----------
# Emscripten.cmake sets TARGET_SUPPORTS_SHARED_LIBS=FALSE, which makes CMake
# silently convert MODULE libraries to STATIC (producing .a archives).
# Override this right after project() so pybind11_add_module creates a real
# MODULE target that em++ can link into a WASM side module.
patch1_anchor = "project(duckdb_py LANGUAGES CXX)"
patch1_insert = (
    "project(duckdb_py LANGUAGES CXX)\n"
    "\n"
    "# Emscripten: allow MODULE libraries (pybind11 extensions) instead of STATIC\n"
    "if(EMSCRIPTEN)\n"
    "  set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)\n"
    "endif()"
)

if patch1_anchor in text:
    text = text.replace(patch1_anchor, patch1_insert, 1)
    patches_applied += 1
    print("Patch 1/3: Enabled TARGET_SUPPORTS_SHARED_LIBS for Emscripten")
else:
    print("WARNING: Patch 1/3 anchor not found: " + repr(patch1_anchor))

# ---------- Patch 2: Add SIDE_MODULE=1 link flag ----------
# After _duckdb is linked against its dependencies, tell em++ to produce a
# WASM side module (.so with dylink section) instead of a main module.
patch2_anchor = "target_link_libraries(_duckdb PRIVATE _duckdb_dependencies)"
patch2_insert = (
    "target_link_libraries(_duckdb PRIVATE _duckdb_dependencies)\n"
    "\n"
    "# Emscripten: produce a WASM side module (.so) loadable by the main runtime\n"
    "if(EMSCRIPTEN)\n"
    '  target_link_options(_duckdb PRIVATE "SHELL:-s SIDE_MODULE=1")\n'
    "endif()"
)

if patch2_anchor in text:
    text = text.replace(patch2_anchor, patch2_insert, 1)
    patches_applied += 1
    print("Patch 2/3: Added SIDE_MODULE=1 link flag for _duckdb")
else:
    print("WARNING: Patch 2/3 anchor not found: " + repr(patch2_anchor))

# ---------- Patch 3: Guard out GNU ld export flags ----------
# wasm-ld doesn't support --export-dynamic-symbol; insert an EMSCRIPTEN
# no-op guard before the UNIX branch.
patch3_old = (
    "elseif(UNIX AND NOT APPLE)\n"
    "  target_link_options(\n"
    '    _duckdb PRIVATE "LINKER:--export-dynamic-symbol=duckdb_adbc_init"\n'
    '    "LINKER:--export-dynamic-symbol=PyInit__duckdb")'
)

patch3_new = (
    "elseif(EMSCRIPTEN)\n"
    "  # wasm-ld does not support --export-dynamic-symbol; symbol exports are\n"
    "  # handled via SIDE_MODULE linking\n"
    "elseif(UNIX AND NOT APPLE)\n"
    "  target_link_options(\n"
    '    _duckdb PRIVATE "LINKER:--export-dynamic-symbol=duckdb_adbc_init"\n'
    '    "LINKER:--export-dynamic-symbol=PyInit__duckdb")'
)

if patch3_old in text:
    text = text.replace(patch3_old, patch3_new, 1)
    patches_applied += 1
    print("Patch 3/3: Added EMSCRIPTEN guard before UNIX export-symbol branch")
else:
    print("WARNING: Patch 3/3 anchor not found")

# ---------- Write result ----------
if patches_applied == 0:
    print("ERROR: No patches were applied!")
    sys.exit(1)

cmake.write_text(text)
print(f"\nDone: {patches_applied}/3 patches applied to CMakeLists.txt")
