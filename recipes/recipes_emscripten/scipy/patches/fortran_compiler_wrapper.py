#!/usr/bin/env python

# This file was adjusted from pyodide "_f2c_fixes.py"
# https://github.com/pyodide/pyodide/blob/main/pyodide-build/pyodide_build/_f2c_fixes.py

import re
from pathlib import Path
from textwrap import dedent  # for doctests
from typing import Iterable, Iterator
import sys
import os
import subprocess
from pathlib import Path

def prepare_doctest(x: str) -> list[str]:
    return dedent(x).strip().splitlines(True)

def fix_f2c_input(f2c_input: Path) -> None:
    if f2c_input.name.endswith("_flapack-f2pywrappers.f"):
        content = f2c_input.read_text()
        content = content.replace("character cmach", "integer cmach")
        content = content.replace("character norm", "integer norm")
        f2c_input.write_text(content)
        return

    if f2c_input.name in [
        "_lapack_subroutine_wrappers.f",
        "_blas_subroutine_wrappers.f",
    ]:
        content = f2c_input.read_text()
        content = content.replace("character", "integer")
        content = content.replace(
            "ret = chla_transtype(", "call chla_transtype(ret, 1,"
        )
        f2c_input.write_text(content)



def fix_string_args(line: str) -> str:
    """
    The two functions ilaenv and xerbla have real string args, f2c generates
    inaccurate signatures for them. Instead of manually fixing the signatures
    (xerbla happens a lot) we inject wrappers called `xerblaf2py` and
    `ilaenvf2py` that have the signatures f2c expects and call these instead.

    Also, replace all single character strings in (the first line of) "call"
    statements with their ascci codes.
    """
    line = re.sub("ilaenv", "ilaenvf2py", line, flags=re.I)
    if (
        not re.search("call", line, re.I)
        and "SIGNST" not in line
        and "TRANST" not in line
    ):
        return line
    if re.search("xerbla", line, re.I):
        return re.sub("xerbla", "xerblaf2py", line, flags=re.I)
    else:
        return re.sub("'[A-Za-z0-9]'", lambda y: str(ord(y.group(0)[1])), line)


def char1_to_int(x: str) -> str:
    """
    Replace multicharacter strings with the ascii code of their first character.

    >>> char1_to_int("CALL sTRSV( 'UPPER', 'NOTRANS', 'NONUNIT', J, H, LDH, Y, 1 )")
    'CALL sTRSV( 85, 78, 78, J, H, LDH, Y, 1 )'
    """
    return re.sub("'(.)[A-Za-z -]*'", lambda r: str(ord(r.group(1))), x)


def char1_args_to_int(lines: list[str]) -> list[str]:
    """
    Replace strings with the ascii code of their first character if they are
    arguments to one of a long list of hard coded LAPACK functions (see
    fncstems). This handles multiline function calls.

    >>> print(char1_args_to_int(["CALL sTRSV( 'UPPER', 'NOTRANS', 'NONUNIT', J, H, LDH, Y, 1 )"]))
    ['CALL sTRSV( 85, 78, 78, J, H, LDH, Y, 1 )']

    >>> print("".join(char1_args_to_int(prepare_doctest('''
    ...               call cvout (logfil, nconv, workl(ihbds), ndigit,
    ...     &            '_neupd: Last row of the eigenvector matrix for T')
    ...     call ctrmm('Right'   , 'Upper'      , 'No transpose',
    ...     &                  'Non-unit', n            , nconv         ,
    ...     &                  one       , workl(invsub), ldq           ,
    ...     &                  z         , ldz)
    ... '''))))
    call cvout (logfil, nconv, workl(ihbds), ndigit,
    &            '_neupd: Last row of the eigenvector matrix for T')
    call ctrmm(82   , 85      , 78,
    &                  78, n            , nconv         ,
    &                  one       , workl(invsub), ldq           ,
    &                  z         , ldz)
    """
    fncstems = [
        "gemm",
        "ggbak",
        "gghrd",
        "lacpy",
        "lamch",
        "lanhs",
        "lanst",
        "larf",
        "lascl",
        "laset",
        "lasr",
        "ormqr",
        "orm2r",
        "steqr",
        "stevr",
        "trevc",
        "trmm",
        "trsen",
        "trsv",
        "unm2r",
        "unmqr",
    ]
    fncnames = []
    for c in "cdsz":
        for stem in fncstems:
            fncnames.append(c + stem)
    fncnames += ["lsame"]

    funcs_pattern = "|".join(fncnames)
    new_lines = []
    replace = False
    for line in lines:
        if re.search(funcs_pattern, line, re.IGNORECASE):
            replace = True
        if replace:
            line = char1_to_int(line)
        if not re.search(r",\s*$", line):
            replace = False
        new_lines.append(line)
    return new_lines


def fix_f2c_output(f2c_output: Path) -> None:
    """
    This function is called on the name of each C output file. It fixes up the C
    output in various ways to compensate for the lack of f2c support for Fortran
    90 and Fortran 95.
    """
    if f2c_output.name == "_lapack_subroutine_wrappers.c":
        content = f2c_output.read_text()
        content = content.replace("integer chla_transtype__", "void chla_transtype__")
        f2c_output.write_text(content)
        return

    if f2c_output.name.endswith("eupd.c"):
        content = f2c_output.read_text()
        content = re.sub(
            r"ftnlen\s*(howmny_len|bmat_len),?", "", content, flags=re.MULTILINE
        )
        f2c_output.write_text(content)
        return

    if f2c_output.name.endswith("lansvd.c"):
        content = f2c_output.read_text()
        content += dedent(
            """
            #include <time.h>

            int second_(real *t) {
                *t = clock()/1000;
                return 0;
            }
            """
        )
        f2c_output.write_text(content)
        return



def add_externs_to_structs(lines: list[str]) -> None:
    """
    The fortran "common" keyword is supposed to share variables between a bunch
    of files. f2c doesn't handle this correctly (it isn't possible for it to
    handle it correctly because it only looks one file at a time).

    We mark all the structs as externs and then (separately) add one non extern
    version to each file.
    >>> lines = prepare_doctest('''
    ...     struct {    doublereal rls[218];
    ...         integer ils[39];
    ...     } ls0001_;
    ...     struct {    doublereal rlsa[22];
    ...         integer ilsa[9];
    ...     } lsa001_;
    ...     struct {    integer ieh[2];
    ...     } eh0001_;
    ... ''')
    >>> add_externs_to_structs(lines)
    >>> print("".join(lines))
    extern struct {    doublereal rls[218];
        integer ils[39];
    } ls0001_;
    extern struct {    doublereal rlsa[22];
        integer ilsa[9];
    } lsa001_;
    extern struct {    integer ieh[2];
    } eh0001_;
    """
    for idx, line in enumerate(lines):
        if line.startswith("struct"):
            lines[idx] = "extern " + lines[idx]


def regroup_lines(lines: Iterable[str]) -> Iterator[str]:
    """
    Make sure that functions and declarations have their argument list only on
    one line.

    >>> print("".join(regroup_lines(prepare_doctest('''
    ...     /* Subroutine */ int clanhfwrp_(real *ret, char *norm, char *transr, char *
    ...         uplo, integer *n, complex *a, real *work, ftnlen norm_len, ftnlen
    ...         transr_len, ftnlen uplo_len)
    ...     {
    ...        static doublereal psum[52];
    ...        extern /* Subroutine */ int dqelg_(integer *, doublereal *, doublereal *,
    ...            doublereal *, doublereal *, integer *);
    ... '''))))
    /* Subroutine */ int clanhfwrp_(real *ret, char *norm, char *transr, char * uplo, integer *n, complex *a, real *work, ftnlen norm_len, ftnlen transr_len, ftnlen uplo_len){
       static doublereal psum[52];
       extern /* Subroutine */ int dqelg_(integer *, doublereal *, doublereal *, doublereal *, doublereal *, integer *);

    """
    line_iter = iter(lines)
    for line in line_iter:
        if "/* Subroutine */" not in line:
            yield line
            continue

        is_definition = line.startswith("/* Subroutine */")
        stop = ")" if is_definition else ";"
        if stop in line:
            yield line
            continue

        sub_lines = [line.rstrip()]
        for line in line_iter:
            sub_lines.append(line.strip())
            if stop in line:
                break
        joined_line = " ".join(sub_lines)
        if is_definition:
            yield joined_line
        else:
            yield from (x + ";" for x in joined_line.split(";")[:-1])


def fix_inconsistent_decls(lines: list[str]) -> list[str]:
    """
    Fortran functions in id_dist use implicit casting of function args which f2c
    doesn't support.

    The fortran equivalent of the following code:

        double f(double x){
            return x + 5;
        }
        double g(int x){
            return f(x);
        }

    gets f2c'd to:

        double f(double x){
            return x + 5;
        }
        double g(int x){
            double f(int);
            return f(x);
        }

    which fails to compile because the declaration of f type clashes with the
    definition. Gather up all the definitions in each file and then gathers the
    declarations and fixes them if necessary so that the declaration matches the
    definition.

    >>> print("".join(fix_inconsistent_decls(prepare_doctest('''
    ...    /* Subroutine */ double f(double x){
    ...        return x + 5;
    ...    }
    ...    /* Subroutine */ double g(int x){
    ...        extern /* Subroutine */ double f(int);
    ...        return f(x);
    ...    }
    ... '''))))
    /* Subroutine */ double f(double x){
        return x + 5;
    }
    /* Subroutine */ double g(int x){
        extern /* Subroutine */ double f(double);
        return f(x);
    }
    """
    func_types = {}
    lines = list(regroup_lines(lines))
    for line in lines:
        if not line.startswith("/* Subroutine */"):
            continue
        [func_name, types] = get_subroutine_decl(line)
        func_types[func_name] = types

    for idx, line in enumerate(lines):
        if "extern /* Subroutine */" not in line:
            continue
        decls = line.split(")")[:-1]
        for decl in decls:
            [func_name, types] = get_subroutine_decl(decl)
            if func_name not in func_types or types == func_types[func_name]:
                continue
            types = func_types[func_name]
            l = list(line.partition(func_name + "("))
            l[2:] = list(l[2].partition(")"))
            l[2] = ", ".join(types)
            line = "".join(l)
        lines[idx] = line
    return lines


def get_subroutine_decl(sub: str) -> tuple[str, list[str]]:
    """
    >>> get_subroutine_decl(
    ...     "extern /* Subroutine */ int dqelg_(integer *, doublereal *, doublereal *, doublereal *, doublereal *, integer *);"
    ... )
    ('dqelg_', ['integer *', 'doublereal *', 'doublereal *', 'doublereal *', 'doublereal *', 'integer *'])
    """
    func_name = sub.partition("(")[0].rpartition(" ")[2]
    args_str = sub.partition("(")[2].partition(")")[0]
    args = args_str.split(",")
    types = []
    for arg in args:
        arg = arg.strip()
        if "*" in arg:
            type = "".join(arg.partition("*")[:-1])
        else:
            type = arg.partition(" ")[0]
        types.append(type.strip())
    return (func_name, types)


def remove_from_list(vals, l):
    for v in vals:
        if v in l:
            l.remove(v)

def compiler_wrapper(args: list[str]):
    if '-dumpversion' in args:
        print("GNU Fortran (Ubuntu/Linaro 4.6.1-9ubuntu3) 9.0.0")
        return
    else:
        new_args = []
        for arg in args:
            if arg.endswith(".f") or arg.endswith(".F"):
                filepath = Path(arg).resolve()
                fix_f2c_input(filepath)
                if arg.endswith(".F"):
                    # .F files apparently expect to be run through the C
                    # preprocessor (they have #ifdef's in them)
                    subprocess.check_call(
                        [
                            "x86_64-conda-linux-gnu-gcc",
                            "-E",
                            "-C",
                            "-P",
                            str(filepath),
                            "-o",
                            str(filepath.with_suffix(".f")),
                        ]
                    )
                    filepath = filepath.with_suffix(".f")
                subprocess.check_call(["f2c","-R", filepath.name], cwd=filepath.parent)
                c_file = filepath.with_suffix('.c')
                fix_f2c_output(c_file)
                new_args.append(str(c_file))
            else:
                new_args.append(arg)

        remove_from_list(['-ffixed-form', '-fno-second-underscore', '-lgfortran', '-Minform=inform', '-module', '-lflang', '-lpgmath', '-pthread'], new_args)
        new_args += ["-I", f"{os.environ['BUILD_PREFIX']}/include"]
        # new_args += ["-Wl,--allow-multiple-definition"]
        if ('-print-libgcc-file-name' in new_args or '-print-file-name=libgfortran.so' in new_args):
            subprocess.check_call(["gcc"] + new_args)
        else:
            subprocess.check_call(["emcc"] + new_args)
 
if __name__ == "__main__":
    compiler_wrapper(sys.argv[1:])

# def replay_f2c(args: list[str], dryrun: bool = False) -> list[str] | None:
#     """Apply f2c to compilation arguments

#     Parameters
#     ----------
#     args
#        input compiler arguments
#     dryrun
#        if False run f2c on detected fortran files

#     Returns
#     -------
#     new_args
#        output compiler arguments


#     Examples
#     --------

#     >>> replay_f2c(['gfortran', 'test.f'], dryrun=True)
#     ['gcc', 'test.c']
#     """
#     new_args = ["gcc"]
#     found_source = False
#     for arg in args[1:]:
#         if arg.endswith(".f") or arg.endswith(".F"):
#             filepath = Path(arg).resolve()
#             if not dryrun:
#                 fix_f2c_input(arg)
#                 if arg.endswith(".F"):
#                     # .F files apparently expect to be run through the C
#                     # preprocessor (they have #ifdef's in them)
#                     subprocess.check_call(
#                         [
#                             "gcc",
#                             "-E",
#                             "-C",
#                             "-P",
#                             filepath,
#                             "-o",
#                             filepath.with_suffix(".f"),
#                         ]
#                     )
#                     filepath = filepath.with_suffix(".f")
#                 subprocess.check_call(["f2c", filepath.name], cwd=filepath.parent)
#                 fix_f2c_output(arg[:-2] + ".c")
#             new_args.append(arg[:-2] + ".c")
#             found_source = True
#         else:
#             new_args.append(arg)

#     new_args_str = " ".join(args)
#     if ".so" in new_args_str and "libgfortran.so" not in new_args_str:
#         found_source = True

#     if not found_source:
#         print(f"f2c: source not found, skipping: {new_args_str}")
#         return None
#     return new_args
