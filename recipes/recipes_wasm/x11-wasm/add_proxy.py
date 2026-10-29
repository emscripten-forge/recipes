#!/usr/bin/env python3
"""Mark every x11.wasm js-library entry point as proxied to the main thread.

x11.wasm's DOM backend (canvases, event listeners, `document`) only exists on
the browser main thread. In a pthreads build every Java thread -- including
AWT's toolkit thread and the EDT -- is a Web Worker, so without proxying the
X11WasmJs* functions would run in a worker where the backend is missing.

Adding `<name>__proxy: "sync"` makes Emscripten run the function on the main
thread and block the calling worker until it returns. That requires the final
program to be linked with -sPROXY_TO_PTHREAD so the main thread stays free.

Usage: add_proxy.py js/emscripten/library/*.js   (edits files in place)
"""
import re
import sys

ENTRY = re.compile(r'^(?P<indent>\s*)(?P<name>X11WasmJs[A-Za-z0-9_]*)\s*:\s*function\b', re.M)

total = 0
found = 0
for path in sys.argv[1:]:
    with open(path, encoding="utf-8") as fh:
        src = fh.read()

    already = set(re.findall(r'(X11WasmJs[A-Za-z0-9_]*)__proxy\s*:', src))
    found += len(ENTRY.findall(src))

    def add(match):
        global total
        name = match.group("name")
        if name in already:
            return match.group(0)
        total += 1
        return f'{match.group("indent")}{name}__proxy: "sync",\n{match.group(0)}'

    src = ENTRY.sub(add, src)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(src)

print(f"add_proxy.py: {found} entry points, newly proxied {total}", file=sys.stderr)
if found == 0:
    sys.exit("add_proxy.py: no X11WasmJs* entry points found; x11.wasm layout changed?")
