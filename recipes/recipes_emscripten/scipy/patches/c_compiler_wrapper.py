# This file was adjusted from pyodide "_f2c_fixes.py"
# https://github.com/pyodide/pyodide/blob/main/pyodide-build/pyodide_build/_f2c_fixes.py

import sys
import re
from pathlib import Path


def scipy_fix_cfile(path: Path) -> None:
    """
    Replace void return types with int return types in various generated .c and
    .h files. We can't achieve this with a simple patch because these files are
    not in the sdist, they are generated as part of the build.
    """
    text = path.read_text()
    text = text.replace("extern void F_WRAPPEDFUNC", "extern int F_WRAPPEDFUNC")
    text = text.replace("extern void F_FUNC", "extern int F_FUNC")
    text = text.replace("void (*f2py_func)", "int (*f2py_func)")
    text = text.replace("static void cb_", "static int cb_")
    text = text.replace("typedef void(*cb_", "typedef int(*cb_")
    text = text.replace("void(*)", "int(*)")
    text = text.replace("static void f2py_setup_", "static int f2py_setup_")


    text = re.sub(
        r"(__Pyx_IsSameCFunction\([^,]+,\s*)\(int\(\*\)\(void\)\)",
        r"\1(void(*)(void))",
        text,
    )

    if path.name.endswith("_flapackmodule.c"):
        text = text.replace(",size_t", "")
        text = re.sub(r",slen\([a-z]*\)\)", ")", text)

    path.write_text(text)

    for lib in ["lapack", "blas"]:
        if path.name.endswith(f"cython_{lib}.c"):
            header_name = f"_{lib}_subroutines.h"
            header_dir = path.parent
            header_path = find_header(header_dir, header_name)

            header_text = header_path.read_text()
            header_text = header_text.replace("void F_FUNC", "int F_FUNC")
            header_path.write_text(header_text)


def find_header(source_dir: Path, header_name: str) -> Path:
    """
    Find the header file that corresponds to a source file.
    """
    while not (header_path := source_dir / header_name).exists():
        # meson copies the source files into a subdirectory of the build
        source_dir = source_dir.parent
        if source_dir == Path("/"):
            raise RuntimeError(f"Could not find header file {header_name}")

    return header_path





def scipy_fixes(args: list[str]) -> None:
    
    for arg in args:
        if "pthread" in args:
            raise RuntimeError("no thread pls",args)

    for arg in args:
        if arg.endswith(".c"):
            scipy_fix_cfile(Path(arg))