
import argparse
import os
from . generic_testing import generic_testing
def main():

    # first argument is the name of the package to test
    parser = argparse.ArgumentParser(description="Run generic tests for a package")


    parser.add_argument("--allow-pthread", action="store_true", help="Allow pthread symbols in the package")

    args = parser.parse_args()

    target_platform = os.environ.get("target_platform")
    assert target_platform is not None, "target_platform environment variable is not set"
    assert target_platform in ["emscripten-wasm32", "emscripten-wasm64"], f"target_platform must be one of ['emscripten-wasm32', 'emscripten-wasm64'], but got {target_platform}"   
    pkg_name = os.environ.get("PKG_NAME")
    pkg_version = os.environ.get("PKG_VERSION")
    pkg_bld_str = os.environ.get("PKG_BUILD_STRING")




    generic_testing(pkg_name=pkg_name,pkg_version=pkg_version, pkg_bld_str=pkg_bld_str, arch=target_platform, allow_pthread=args.allow_pthread)


if __name__ == "__main__":
    main()