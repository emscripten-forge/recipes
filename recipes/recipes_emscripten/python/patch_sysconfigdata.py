if __name__ == "__main__":
    import argparse
    import json
    import os
    from pathlib import Path

    parser = argparse.ArgumentParser(prog="PatchSysConfigData")

    parser.add_argument("--fname-in", required=True)
    parser.add_argument("--fname-out", required=True)

    args = parser.parse_args()

    with open(args.fname_in, "r") as f:
        content = f.read()

    exec(content)

    prefix = os.environ["PREFIX"]
    lib_dir = str(Path(prefix) / "lib")
    include_dir = str(Path(prefix) / "include")

    # build time var is in the global scope because of the 'exec'
    build_time_vars["AR"] = "emar"
    build_time_vars["CC"] = "emcc"
    build_time_vars["CXX"] = "em++"
    build_time_vars["LDCXXSHARED"] = "emcc"
    build_time_vars["LINKCC"] = "emcc"
    build_time_vars["MAINCC"] = "emcc"
    build_time_vars["BLDSHARED"] = f"emcc -L{str(lib_dir)} -sWASM_BIGINT"

    config_args = (
        f"'CFLAGS=-g0 -g0 -fPIC -Wno-implicit-function-declaration' "
        + f"'LDFLAGS=-L{lib_dir} "
        + "  -sWASM_BIGINT' 'PLATFORM_TRIPLET=wasm32-emscripten' "
        + "'MULTIARCH=wasm32-emscripten' '--without-pymalloc' "
        + "'--disable-shared' '--disable-ipv6' '--enable-big-digits=30' "
        + "'--enable-optimizations' '--host=wasm32-unknown-emscripten' "
        + "'--build=x86_64-pc-linux-gnu' "
        + f"'--prefix={str(prefix)}' "
        + "'build_alias=x86_64-pc-linux-gnu' "
        + "'host_alias=wasm32-unknown-emscripten' "
        + "'CC=emcc' "
        + "'PKG_CONFIG_PATH=' "
        + f"'PKG_CONFIG_LIBDIR={str(prefix)}/lib/pkgconfig:{str(prefix)}/lib/pkgconfig'"
    )
    build_time_vars["CONFIG_ARGS"] = config_args

    print(config_args)

    build_time_vars["LDSHARED"] = f"emcc -L{lib_dir} -sWASM_BIGINT"
    build_time_vars["abs_builddir"] = str(prefix)
    build_time_vars["abs_srcdir"] = str(prefix)

    # we need to write the sysconfig data in the following format

    #    build_time_vars = {
    #        "ABIFLAGS": "",
    #        "AC_APPLE_UNIVERSAL_BUILD": 0,
    #        "AIX_BUILDDATE": 0,
    #        "AIX_GENUINE_CPLUSPLUS": 0,
    #        "ALIGNOF_LONG": 4,#
    #       ...
    #    }

    build_time_vars_string = json.dumps(build_time_vars, indent=4)

    content = f"""build_time_vars = {build_time_vars_string}
    """

    with open(args.fname_out, "w") as f:
        f.write(content)
