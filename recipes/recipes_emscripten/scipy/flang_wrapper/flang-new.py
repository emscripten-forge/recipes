
import os
from pathlib import Path
import subprocess

BUILD_PREFIX = os.environ["BUILD_PREFIX"]
ACTUAL_FLANG_BINARY_PATH = Path(BUILD_PREFIX) / "bin" / "flang-new-bak"


def sanetize_arguments(args):

    # replace -03 with -O2
    for i, arg in enumerate(args):
        if arg == "-O3":
            args[i] = "-O2" 

        # if arg == "-module-dir":
        #     args[i] = ""
        #     args[i+1] = ""
    
    # remove all empty strings
    args = list(filter(lambda x: x != "", args))

    # -nostdlib
    args.append("-nostdlib")

    return args

if __name__ == "__main__":
    
    # get all arguments
    import sys
    args = sys.argv[0:]
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
