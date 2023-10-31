import os
import pprint


def load_sysconfig(sysconfig_name: str):
    _temp = __import__(sysconfig_name, globals(), locals(), ["build_time_vars"], 0)
    config_vars = _temp.build_time_vars
    return config_vars, _temp.__file__


def write_sysconfig(destfile: str, config_vars: dict[str, str]):
    with open(destfile, "w", encoding="utf8") as f:
        f.write(
            "# system configuration generated and used by" " the sysconfig module\n"
        )
        f.write("build_time_vars = ")
        pprint.pprint(config_vars, stream=f)


def adjust_sysconfig(config_vars: dict[str, str]):
    config_vars.update(
        CC="emcc",
        MAINCC="emcc",
        LDSHARED="emcc -s MODULARIZE=1  -s LINKABLE=1  -s EXPORT_ALL=1  -s WASM=1  -s SIDE_MODULE=1 -sWASM_BIGINT",
        LINKCC="emcc",
        BLDSHARED="emcc -s MODULARIZE=1  -s LINKABLE=1  -s EXPORT_ALL=1  -s WASM=1  -s SIDE_MODULE=1 -sWASM_BIGINT",
        CXX="emcc",
        LDCXXSHARED="emcc -s MODULARIZE=1  -s LINKABLE=1  -s EXPORT_ALL=1  -s WASM=1  -s SIDE_MODULE=1 -sWASM_BIGINT"
    )


if __name__ == "__main__":
    sysconfig_name = os.environ["SYSCONFIG_NAME"]
    config_vars, file = load_sysconfig(sysconfig_name)
    adjust_sysconfig(config_vars)
    write_sysconfig(file, config_vars)
