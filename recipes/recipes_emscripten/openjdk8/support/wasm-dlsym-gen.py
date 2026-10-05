#!/usr/bin/env python3
"""wasm-dlsym-gen -- build the static symbol table behind the dlopen()/dlsym()
emulation used by the WebAssembly OpenJDK.

All native libraries are linked into one WebAssembly module.  To keep
System.loadLibrary(), JNI native method lookup, JNI_OnLoad_<lib> discovery
(JEP 178) and the many dlsym() calls inside the JDK working, every function
exported by a library is recorded in a table {name, address}.

Taking the address of a function in C requires a prototype whose
WebAssembly signature matches the definition exactly (otherwise wasm-ld
substitutes a trapping stub).  The prototypes are therefore derived from the
function types found in the relocatable objects themselves.

usage: wasm-dlsym-gen.py -o table.c LIB=object.so[:filter] ...
  filter is a regular expression symbols must match (default: all defined
  global functions).
"""
import argparse
import re
import sys

VALTYPES = {0x7f: 'int', 0x7e: 'long long', 0x7d: 'float', 0x7c: 'double'}


def leb_u(b, i):
    result = shift = 0
    while True:
        byte = b[i]
        i += 1
        result |= (byte & 0x7f) << shift
        shift += 7
        if not byte & 0x80:
            return result, i


def read_name(b, i):
    n, i = leb_u(b, i)
    return b[i:i + n].decode('utf-8', 'replace'), i + n


def parse(path):
    b = open(path, 'rb').read()
    if b[:4] != b'\0asm':
        raise ValueError('%s: not a wasm object' % path)
    i = 8
    types, func_types, imported_funcs = [], [], 0
    symbols = []
    while i < len(b):
        sid = b[i]
        i += 1
        size, i = leb_u(b, i)
        end = i + size
        if sid == 1:  # type
            n, j = leb_u(b, i)
            for _ in range(n):
                form = b[j]
                j += 1
                assert form == 0x60
                np_, j = leb_u(b, j)
                params = list(b[j:j + np_])
                j += np_
                nr, j = leb_u(b, j)
                results = list(b[j:j + nr])
                j += nr
                types.append((params, results))
        elif sid == 2:  # import
            n, j = leb_u(b, i)
            for _ in range(n):
                _, j = read_name(b, j)
                _, j = read_name(b, j)
                kind = b[j]
                j += 1
                if kind == 0:
                    _, j = leb_u(b, j)
                    imported_funcs += 1
                elif kind == 1:
                    j += 1
                    flags, j = leb_u(b, j)
                    _, j = leb_u(b, j)
                    if flags & 1:
                        _, j = leb_u(b, j)
                elif kind == 2:
                    flags, j = leb_u(b, j)
                    _, j = leb_u(b, j)
                    if flags & 1:
                        _, j = leb_u(b, j)
                elif kind == 3:
                    j += 2
                elif kind == 4:
                    j += 1
                    _, j = leb_u(b, j)
        elif sid == 3:  # function
            n, j = leb_u(b, i)
            for _ in range(n):
                t, j = leb_u(b, j)
                func_types.append(t)
        elif sid == 0:
            name, j = read_name(b, i)
            if name == 'linking':
                _, j = leb_u(b, j)  # version
                while j < end:
                    stype = b[j]
                    j += 1
                    ssize, j = leb_u(b, j)
                    send = j + ssize
                    if stype == 8:  # symbol table
                        count, k = leb_u(b, j)
                        for _ in range(count):
                            kind = b[k]
                            k += 1
                            flags, k = leb_u(b, k)
                            sname = None
                            if kind in (0, 2, 4, 5):  # function, global, tag, table
                                idx, k = leb_u(b, k)
                                if not (flags & 0x10) or (flags & 0x40):
                                    sname, k = read_name(b, k)
                                if kind == 0:
                                    symbols.append((sname, idx, flags))
                            elif kind == 1:  # data
                                sname, k = read_name(b, k)
                                if not (flags & 0x10):
                                    _, k = leb_u(b, k)
                                    _, k = leb_u(b, k)
                                    _, k = leb_u(b, k)
                            elif kind == 3:  # section
                                _, k = leb_u(b, k)
                    j = send
        i = end
    out = {}
    for name, idx, flags in symbols:
        if name is None or flags & 0x10 or flags & 0x02:  # undefined or local
            continue
        if idx < imported_funcs:
            continue
        params, results = types[func_types[idx - imported_funcs]]
        out[name] = (params, results)
    return out


def c_proto(name, sig):
    params, results = sig
    ret = VALTYPES[results[0]] if results else 'void'
    ps = ', '.join(VALTYPES[p] for p in params) or 'void'
    return 'extern %s %s(%s);' % (ret, name, ps)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-o', '--output', required=True)
    ap.add_argument('--list', help='write "lib symbol" pairs here')
    ap.add_argument('libs', nargs='+', help='LIB=object[:regex]')
    a = ap.parse_args()
    all_syms = {}
    lib_names = []
    for spec in a.libs:
        lib, rest = spec.split('=', 1)
        path, _, rx = rest.partition(':')
        rx = re.compile(rx) if rx else None
        lib_names.append(lib)
        for name, sig in parse(path).items():
            if rx and not rx.search(name):
                continue
            if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', name):
                continue
            if name in all_syms:
                continue  # first definition wins (the linker will complain anyway)
            all_syms[name] = (lib, sig)
    lines = ['/* generated by wasm-dlsym-gen.py -- do not edit */',
             '#include "wasm_dlsym.h"', '']
    for name in sorted(all_syms):
        lines.append(c_proto(name, all_syms[name][1]))
    lines.append('')
    lines.append('const char *const wasm_dl_libraries[] = {')
    for lib in lib_names:
        lines.append('  "%s",' % lib)
    lines.append('  0 };')
    lines.append('')
    lines.append('const struct wasm_dl_symbol wasm_dl_symbols[] = {')
    for name in sorted(all_syms):
        lib = all_syms[name][0]
        lines.append('  { "%s", (void *)%s, %d },' % (name, name, lib_names.index(lib)))
    lines.append('};')
    lines.append('const int wasm_dl_symbol_count = %d;' % len(all_syms))
    with open(a.output, 'w') as fh:
        fh.write('\n'.join(lines) + '\n')
    if a.list:
        with open(a.list, 'w') as fh:
            for name in sorted(all_syms):
                fh.write('%s %s\n' % (all_syms[name][0], name))
    print('wasm-dlsym-gen: %d symbols from %d libraries' % (len(all_syms), len(lib_names)),
          file=sys.stderr)


if __name__ == '__main__':
    main()
