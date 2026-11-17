"""Build a PIC Zig archive and link it into Emscripten's shared memory."""

import os
from pathlib import Path
import shlex
import shutil
import subprocess

src = Path(os.environ["SRC_DIR"])
prefix = Path(os.environ["PREFIX"])
recipe = Path(os.environ["RECIPE_DIR"])
os.chdir(src)
os.environ.setdefault("ZIG_GLOBAL_CACHE_DIR", str(src / "zig-global-cache"))
zig = next(
    (
        shutil.which(command)
        for command in (os.environ.get("ZIG"), os.environ.get("CONDA_ZIG_BUILD"), "zig")
        if command and shutil.which(command)
    ),
    None,
)
if zig is None:
    raise RuntimeError("Cannot find the build-platform Zig compiler")

subprocess.run(
    [
        zig,
        "build",
        "-Demit-lib-vt=true",
        "-Demit-xcframework=false",
        "--prefix",
        str(prefix),
        "--system",
        str(src / "vt-deps"),
        "-Dtarget=wasm32-emscripten",
        "-Dcpu=baseline",
        "-Doptimize=fast",
        "-Dsimd=false",
        "-Dapp-runtime=none",
        "-Demit-exe=false",
        "-Demit-docs=false",
        "-Demit-macos-app=false",
    ],
    check=True,
)

# Upstream's Wasm artifact is a standalone module with its own memory/table.
# Link the archive with emcc so Python/CFFI can dlopen it in the host runtime.
archive = prefix / "lib/libghostty-vt.a"
shared = prefix / "lib/libghostty-vt.so"
flags = shlex.split(os.environ.get("CFLAGS", ""))
subprocess.run(
    [
        "emcc",
        *flags,
        "-O2",
        "-sSIDE_MODULE=1",
        "-shared",
        "-Wl,--whole-archive",
        str(archive),
        "-Wl,--no-whole-archive",
        "-o",
        str(shared),
    ],
    check=True,
)
shutil.copytree(src / "include/ghostty", prefix / "include/ghostty", dirs_exist_ok=True)

pkgconfig = prefix / "lib/pkgconfig"
pkgconfig.mkdir(parents=True, exist_ok=True)
for static in (False, True):
    name = "libghostty-vt-static" if static else "libghostty-vt"
    libs = "${libdir}/libghostty-vt.a" if static else "-L${libdir} -lghostty-vt"
    cflags = "-I${includedir}" + (" -DGHOSTTY_STATIC" if static else "")
    (pkgconfig / f"{name}.pc").write_text(
        f"prefix={prefix}\nlibdir=${{prefix}}/lib\nincludedir=${{prefix}}/include\n\n"
        f"Name: {name}\nDescription: Ghostty VT parsing library\n"
        f"Version: {os.environ['PKG_VERSION']}\nLibs: {libs}\nCflags: {cflags}\n"
    )

# Execute the same C API test twice: once linked statically and once via
# dlopen/dlsym. The latter exercises the path used by ABI-mode Python CFFI.
for dynamic in (False, True):
    output = src / ("test-dynamic.js" if dynamic else "test-static.js")
    options = (
        [
            "-DTEST_DYNAMIC",
            "-sMAIN_MODULE=1",
            "--preload-file",
            f"{shared}@/libghostty-vt.so",
        ]
        if dynamic
        else [str(archive)]
    )
    subprocess.run(
        [
            "emcc",
            *flags,
            "-O2",
            "-UNDEBUG",
            "-I" + str(prefix / "include"),
            str(recipe / "test-lib.c"),
            *options,
            "-sEXIT_RUNTIME=1",
            "-sALLOW_MEMORY_GROWTH=1",
            "-o",
            str(output),
        ],
        check=True,
    )
    subprocess.run(["node", str(output)], check=True, timeout=120)
