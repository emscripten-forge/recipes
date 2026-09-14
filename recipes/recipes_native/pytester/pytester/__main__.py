import pyjs_code_runner
import socket
from contextlib import closing, contextmanager
import os
from pyjs_code_runner.run import run
from pyjs_code_runner.backend.backend import BackendType
from pyjs_code_runner.get_file_filter import get_file_filter
from pathlib import Path
import shutil
import sys
import pprint
# dir of this file
THIS_DIR = os.path.dirname(os.path.realpath(__file__))
MAIN_MOUNT_DIR= Path(THIS_DIR) /"main_mount"
EMPACK_CONFIG= str(Path(THIS_DIR) / "empack_config.yaml")

def find_free_port():
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as s:
        s.bind(("", 0))
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        return s.getsockname()[1]
    



def main():
    print("Running the main function")
    # get the conda env from the env var "PREFIX"
    prefix = os.environ["PREFIX"]

    print(f"load file filter from  {EMPACK_CONFIG}")
    file_filter = get_file_filter([EMPACK_CONFIG])
    print(file_filter)


    # get cwd
    work_dir = os.getcwd()
    print("Current working directory is: ", work_dir)

    # find all "test_*.py" files in the current directory
    print("Finding all test files in the current directory")
    test_files = [f for f in os.listdir(work_dir) if f.startswith("test_") and f.endswith(".py")]

    # pprint test_files
    print("Test files found:")
    pprint.pprint(test_files)


    print("create a dir in the current work_dir named 'tests'")
    # create a dir in the current work_dir named "tests"


    tests_dir = Path(work_dir) / "tests"
    tests_dir.mkdir(exist_ok=True)

    print("copy all test files to the 'tests' dir")

    # copy all test files to the "tests" dir
    for test_file in test_files:
        shutil.copy(test_file, tests_dir)
    


    # work dir in the virtual file system
    virtual_work_dir = Path("/home/web_user/tests")
    


    backends = [
        (
            BackendType.browser_worker,
            lambda: dict(port=find_free_port(), slow_mo=1, headless=True, preload_shared_libs=False)
        ),
        (
            BackendType.browser_worker,
            lambda: dict(port=find_free_port(), slow_mo=1, headless=True, preload_shared_libs=True)
        ),
        (
            BackendType.browser_main,
            lambda: dict(port=find_free_port(), slow_mo=1, headless=True),
        )
    ]
    print(
        "================================================================================"
    )
    print(
        "======================= Main test session starts ==============================="
    )
    exceptions = []
    for backend_type, backend_kwargs_factory in backends:
        print(
            "================================================================================"
        )
        preload_shared_libs = backend_kwargs_factory().get("preload_shared_libs", True)
        print(f"Test backend: {backend_type}, preload_shared_libs: {preload_shared_libs}")
        print(
            "================================================================================"
        )
        try:
            run(
                conda_env=prefix,
                relocate_prefix="/",
                backend_type=backend_type,
                script="main.py",
                async_main=False,
                mounts=[
                    (MAIN_MOUNT_DIR, virtual_work_dir),
                    (Path(tests_dir).resolve(), virtual_work_dir),
                ],
                work_dir=virtual_work_dir,
                pkg_file_filter=file_filter,
                pyjs_dir=None,
                cache_dir=None,
                use_cache=False,
                host_work_dir=None,
                backend_kwargs=backend_kwargs_factory(),
            )
        except Exception as e:
            print(f"Test  backend : {backend_type}, preload_shared_libs: {preload_shared_libs} FAILED {e}")
            exceptions.append(e)
    
    if exceptions:
        sys.exit(1)
    sys.exit(0)





if __name__ == "__main__":
    
    main()