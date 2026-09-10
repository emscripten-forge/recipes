#!/usr/bin/env python3
"""Helper to regenerate the flang OpenBLAS Fortran ABI patch for NumPy.

Background
----------
Flang emits Fortran subroutines as returning void and appends a hidden
character-length argument for each CHARACTER dummy. NumPy's wrappers still
follow the f2c/g77 convention (int return, no length args). wasm-ld rejects
the resulting signature mismatches when linking against the emscripten-forge
OpenBLAS package (built with flang-new).

The recipe applies an explicit source patch (SciPy-style), not this script,
at build time:

  patches/0001-Match-flang-OpenBLAS-Fortran-ABI-on-Emscripten-wasm32.patch

Keep this script around to regenerate that patch when NumPy's Fortran
wrappers change upstream.

Usage — edit files in place
---------------------------
From an extracted NumPy source tree (matching the recipe version)::

  python3 fix_flang_fortran_abi.py \\
      numpy/linalg/lapack_litemodule.c \\
      numpy/linalg/umath_linalg.cpp \\
      numpy/linalg/lapack_lite/python_xerbla.c \\
      numpy/_core/src/common/python_xerbla.c

Usage — regenerate the recipe patch
-----------------------------------
::

  # Extract the same NumPy tarball as in recipe.yaml, then:
  git init && git add <the four files above> && git commit -m baseline
  python3 path/to/fix_flang_fortran_abi.py <the four files>
  git add <the four files>
  git commit  # use the commit message from the existing .patch Subject/body
  git format-patch -1 --stdout > \\
      recipes/recipes_emscripten/numpy/patches/\\
      0001-Match-flang-OpenBLAS-Fortran-ABI-on-Emscripten-wasm32.patch

What it changes
---------------
- Fortran subroutine prototypes: ``fortran_int`` -> ``void``
- One trailing ``int`` formal per ``char *`` parameter
- Call sites: pass length actual ``1`` for each CHARACTER argument
- Drop uses of subroutine return values (``info`` / ``return 0``)
- ``python_xerbla``: ``void`` return + ``srname_len`` argument

Fortran *functions* that keep a non-void return (``sdot``, ``ddot``) are
left unchanged.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# Fortran *functions* that must keep a non-void return type.
KEEP_RETURN = {"sdot", "ddot"}


def count_char_params(proto: str) -> int:
    return len(re.findall(r"\bchar\s*\*", proto))


def append_char_lengths(args: str, n: int) -> str:
    if n <= 0:
        return args
    if re.search(r"(?:,\s*1)+\s*$", args):
        return args
    return args + "".join(", 1" for _ in range(n))


def find_matching_paren(text: str, open_idx: int) -> int:
    """Return index of the ')' matching text[open_idx] == '('."""
    depth = 0
    for i in range(open_idx, len(text)):
        ch = text[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
    raise ValueError("unbalanced parentheses")


def iter_fortran_calls(text: str):
    """Yield (start, end, callee, name, args) for FNAME|LAPACK|BLAS(name)(args)."""
    for m in re.finditer(r"(?:FNAME|LAPACK|BLAS)\((\w+)\)\s*\(", text):
        name = m.group(1)
        callee_end = m.end() - 1  # index of '(' starting args
        # Find start of callee token
        callee_start = m.start()
        try:
            close = find_matching_paren(text, callee_end)
        except ValueError:
            continue
        args = text[callee_end + 1 : close]
        callee = text[callee_start : callee_end]
        yield callee_start, close + 1, callee, name, args


def is_prototype_args(args: str) -> bool:
    """True if this argument list looks like a C/C++ prototype, not a call."""
    if re.search(r"\bchar\s*\*[A-Za-z_]", args):
        return True
    if re.search(r"\[[^\]]*\]", args):
        return True
    if re.search(r"\b(?:float|double|fortran_int|f2c_\w+)\s+\*?[A-Za-z_]", args):
        return True
    if re.search(r",\s*int(\s*,\s*int)*\s*$", args):
        return True
    return False


def collect_char_counts(text: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for m in re.finditer(r"FNAME\((\w+)\)\s*\(", text):
        name = m.group(1)
        open_idx = m.end() - 1
        try:
            close = find_matching_paren(text, open_idx)
        except ValueError:
            continue
        proto = text[open_idx + 1 : close]
        # Only learn from prototypes, never from call sites.
        if not is_prototype_args(proto):
            continue
        counts[name] = count_char_params(proto)
    return counts


def fix_externs(text: str) -> str:
    """void-ify Fortran subroutine prototypes and append char-length formals."""

    out: list[str] = []
    i = 0
    pattern = re.compile(r"extern(?:\s+\"C\")?\s+fortran_int\s+")

    while True:
        m = pattern.search(text, i)
        if not m:
            out.append(text[i:])
            break
        out.append(text[i : m.start()])
        # Expect FNAME(name)(proto);
        rest = text[m.end() :]
        fm = re.match(r"FNAME\((\w+)\)\s*\(", rest)
        if not fm:
            out.append(text[m.start() : m.end()])
            i = m.end()
            continue
        name = fm.group(1)
        open_idx = m.end() + fm.end() - 1
        close = find_matching_paren(text, open_idx)
        if close + 1 < len(text) and text[close + 1] == ";":
            end = close + 2
        else:
            out.append(text[m.start() : m.end()])
            i = m.end()
            continue
        proto = text[open_idx + 1 : close]
        if name in KEEP_RETURN:
            out.append(text[m.start() : end])
        else:
            n_char = count_char_params(proto)
            if n_char:
                proto = re.sub(r"(?:,\s*int)+$", "", proto)
                proto = proto + "".join(", int" for _ in range(n_char))
            # Preserve "extern" / 'extern "C"' prefix and spacing before FNAME.
            prefix = text[m.start() : m.end()].replace("fortran_int", "void", 1)
            out.append(f"{prefix}FNAME({name})({proto});")
        i = end

    return "".join(out)


def fix_calls(text: str, char_counts: dict[str, int]) -> str:
    """Append flang char-length actuals and drop void subroutine return uses."""

    # Process from end to start so indices stay valid.
    replacements: list[tuple[int, int, str]] = []

    for start, end, callee, name, args in iter_fortran_calls(text):
        if is_prototype_args(args):
            continue
        n = char_counts.get(name, 0)
        new_args = append_char_lengths(args, n) if n else args
        new_call = f"{callee}({new_args})"

        # return <call>;
        before = text[:start].rstrip()
        after = text[end:].lstrip()
        if before.endswith("return") and name not in KEEP_RETURN and after.startswith(";"):
            # Replace `return call;` with `call; return 0;`
            # Expand to include 'return' and ';'
            ret_start = text.rfind("return", 0, start)
            semi = text.find(";", end)
            replacements.append((ret_start, semi + 1, f"{new_call}; return 0;"))
            continue

        # lapack_lite_status = <call>;
        if re.search(r"lapack_lite_status\s*=\s*$", text[:start]) and name not in KEEP_RETURN:
            assign_start = text.rfind("lapack_lite_status", 0, start)
            semi = text.find(";", end)
            replacements.append(
                (assign_start, semi + 1, f"{new_call};\n        lapack_lite_status = info;")
            )
            continue

        if new_args != args:
            replacements.append((start, end, new_call))

    for start, end, repl in sorted(replacements, reverse=True):
        text = text[:start] + repl + text[end:]
    return text


def fix_python_xerbla(text: str) -> str:
    """Match flang OpenBLAS xerbla: void return + character length argument."""
    text = text.replace(
        "CBLAS_INT BLAS_FUNC(xerbla)(char *srname, CBLAS_INT *info)",
        "void BLAS_FUNC(xerbla)(char *srname, CBLAS_INT *info, int srname_len)",
    )
    text = re.sub(
        r"(PyGILState_Release\(save\);\n)\s*return 0;\n(\})",
        r"\1\2",
        text,
    )
    text = text.replace(
        "while( len<6 && srname[len]!='\\0' )",
        "while( len<6 && len<srname_len && srname[len]!='\\0' )",
    )
    return text


def process_file(path: Path) -> None:
    original = path.read_text()
    text = original
    if path.name == "python_xerbla.c":
        text = fix_python_xerbla(text)
    else:
        char_counts = collect_char_counts(text)
        text = fix_externs(text)
        # Recompute after prototype rewrite (names unchanged; counts same).
        text = fix_calls(text, char_counts)
    if text == original:
        print(f"warning: no changes in {path}", file=sys.stderr)
    else:
        path.write_text(text)
        print(f"patched {path}")


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__.strip(), file=sys.stderr)
        print(f"\nusage: {argv[0]} FILE [FILE...]", file=sys.stderr)
        return 2
    for arg in argv[1:]:
        process_file(Path(arg))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
