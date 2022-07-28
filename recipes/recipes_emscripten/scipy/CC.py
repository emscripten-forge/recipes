#!/usr/bin/env python

import sys
from pathlib import Path

def scipy_fix_cfile(path: str) -> None:
    """
    Replace void return types with int return types in various generated .c and
    .h files. We can't achieve this with a simple patch because these files are
    not in the sdist, they are generated as part of the build.
    """
    source_path = Path(path)
    text = source_path.read_text()
    text = text.replace("extern void F_WRAPPEDFUNC", "extern int F_WRAPPEDFUNC")
    text = text.replace("extern void F_FUNC", "extern int F_FUNC")
    text = text.replace("void (*f2py_func)", "int (*f2py_func)")
    text = text.replace("static void cb_", "static int cb_")
    text = text.replace("typedef void(*cb_", "typedef int(*cb_")
    text = text.replace("void(*)", "int(*)")
    text = text.replace("static void f2py_setup_", "static int f2py_setup_")

    if path.endswith("_flapackmodule.c"):
        text = text.replace(",size_t", "")
        text = re.sub(r",slen\([a-z]*\)\)", ")", text)

    if path.endswith("_fblasmodule.c"):
        text = text.replace(" float (*f2py_func)", " double (*f2py_func)")

    source_path.write_text(text)

    for lib in ["lapack", "blas"]:
        if path.endswith(f"cython_{lib}.c"):
            header_path = Path(path).with_name(f"_{lib}_subroutines.h")
            header_text = header_path.read_text()
            header_text = header_text.replace("void F_FUNC", "int F_FUNC")
            header_path.write_text(header_text)


def scipy_fixes(args: list[str]) -> None:
    for arg in args:
        if arg.endswith(".c"):
            scipy_fix_cfile(arg)

def compiler_wrapper(args: list[str]):
	scipy_fixes(args)

	pp = Path(__file__).parent()

	if __file__.endswith('em++'):
	    subprocess.check_call([str(pp / "em++-orig")] + args)
	else:
	    subprocess.check_call([str(pp / "emcc-orig")] + args)

if __name__ == "__main__":
    compiler_wrapper(sys.argv[1:])

