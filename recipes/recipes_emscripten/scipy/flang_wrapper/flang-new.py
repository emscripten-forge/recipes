
import os
from pathlib import Path
import subprocess

BUILD_PREFIX = os.environ["BUILD_PREFIX"]
ACTUAL_FLANG_BINARY_PATH = Path(BUILD_PREFIX) / "bin" / "flang-new-bak"


def sanetize_arguments(args):
    # # make one big space separated string
    # args = " ".join(args)

    # # replace "-sSHARED=1" with ""
    # args = args.replace("-sSIDE_MODULE=1", "")
    # args = args.replace("-s SIDE_MODULE=1", "")

    # #  -sWASM_BIGINT
    # args = args.replace("-sWASM_BIGINT", "")
    # args = args.replace("-s WASM_BIGINT", "")

    # # -sWASM=1
    # args = args.replace("-sWASM=1", "")
    # args = args.replace("-s WASM=1", "")

    # # -sERROR_ON_UNDEFINED_SYMBOLS=0 
    # args = args.replace("-sERROR_ON_UNDEFINED_SYMBOLS=0", "")
    # args = args.replace("-s ERROR_ON_UNDEFINED_SYMBOLS=0", "")


    # # # -shared
    # # args = args.replace("-shared", "")


    # # in some testscripts to check if a certain flag working we see "output.js" in the arguments instead of .wasm
    # # we need to replace it with .wasm
    # args = args.replace("output.js", "output.wasm")

    # # -U _OPENMP
    # args = args.replace("-U _OPENMP", "")
    # args = args.replace("-U_OPENMP", "")

    # # # ignore -O2
    # # args = args.replace("-O2", "")



    # # make a list of arguments again
    # args = args.split(" ")

    # # remove empty strings
    # args = [arg for arg in args if arg != ""]


    # -nostdlib
    args.append("-nostdlib")

    return args

if __name__ == "__main__":
    
    # get all arguments
    import sys
    args = sys.argv[1:]
    fixed_args = sanetize_arguments(args)
    print(f"""THIS IS A FLANG-WRAPPER
    ACTUAL FLANG BINARY: {ACTUAL_FLANG_BINARY_PATH}
    Passed arguments: {args}
    Sanetized arguments: {fixed_args}
    """)

    # print all current LDFLAGS / CFLAGS / CXXFLAGS

    # print("LDFLAGS: ", os.environ.get("LDFLAGS", ""))
    # print("CFLAGS: ", os.environ.get("CFLAGS", ""))
    # print("CXXFLAGS: ", os.environ.get("CXXFLAGS", ""))

    

    # Run the actual flang binary
    process = subprocess.Popen(
        [str(ACTUAL_FLANG_BINARY_PATH)] + fixed_args,
        stdout=sys.stdout,
        stderr=sys.stderr,
        # env=dict(os.environ, LDFLAGS="", CFLAGS="", CXXFLAGS="")
    )
    
    # Wait for the process to finish and get the return code
    process.wait()
    sys.exit(process.returncode)
