import tempfile
import socket
from contextlib import closing
from pathlib import Path
import os
import subprocess
import fnmatch

from pyjs_code_runner.run import run
from pyjs_code_runner.backend.backend import BackendType

THIS_DIR = Path(os.path.dirname(os.path.realpath(__file__)))
MAIN_MOUNT = THIS_DIR / "main_mount"


def find_free_port():
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as s:
        s.bind(("", 0))
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        return s.getsockname()[1]


def has_pytest_files(recipe_dir):
    recipe_dir = os.path.abspath(recipe_dir)
    for path, folders, files in os.walk(recipe_dir):
        for file in files:
            if fnmatch.fnmatch(file, "test_*.py"):
                return True

    return False


def create_test_env(pkg_name, prefix):
    # cmd = ['$MAMBA_EXE' ,'create','--prefix', prefix,'--platform=emscripten-32'] + [pkg_name] #+ ['--dryrun']
    cmd = [
        f"""$MAMBA_EXE create --yes --prefix {prefix} --platform=emscripten-32   python "pyjs>=0.18.0" pytest {pkg_name}"""
    ]
    ret = subprocess.run(cmd, shell=True)
    #  stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    returncode = ret.returncode
    assert returncode == 0


def get_node_binary():
    conda_prefix = os.getenv("CONDA_PREFIX")
    if conda_prefix is None:
        raise RuntimeError(
            "CONDA_PREFIX environment variable is not set! this is needede to find the node binary"
        )
    conda_prefix = Path(conda_prefix)
    node_binary = conda_prefix / "bin" / "node"
    if node_binary.is_file():
        return node_binary
    else:
        raise RuntimeError(
            "could not find node: make sure node is installed in the current conda env"
        )


def test_package(recipe):
    recipe_dir, _ = os.path.split(recipe["recipe_file"])
    assert os.path.isdir(recipe_dir), f"recipe_dir: {recipe_dir} does not exist"
    recipe_file = os.path.join(recipe_dir, "recipe.yaml")

    old_cwd = os.getcwd()

    if has_pytest_files(recipe_dir):

        pkg_name = recipe["package"]["name"]

        with tempfile.TemporaryDirectory() as temp_dir:

            prefix = os.path.join(temp_dir, "prefix")
            create_test_env(pkg_name=pkg_name, prefix=prefix)

            work_dir = Path("/home/web_user/recipe_dir")

            backends = [
                (
                    BackendType.browser_main,
                    lambda: dict(port=find_free_port(), slow_mo=1, headless=True),
                ),
                (
                    BackendType.browser_worker,
                    lambda: dict(port=find_free_port(), slow_mo=1, headless=True),
                ),
                (BackendType.node, lambda: dict(node_binary=get_node_binary())),
            ]
            print(
                "================================================================================"
            )
            print(
                "======================= Main test session starts ==============================="
            )
            for backend_type, backend_kwargs_factory in backends:
                print(
                    "================================================================================"
                )
                print(f"Test backend: {backend_type}")
                print(
                    "================================================================================"
                )
                r = run(
                    conda_env=prefix,
                    backend_type=backend_type,
                    script="main.py",
                    async_main=True,
                    mounts=[
                        (MAIN_MOUNT, work_dir),
                        (Path(recipe_dir).resolve(), work_dir),
                    ],
                    work_dir=work_dir,
                    pkg_file_filter=None,  # let empack handle this
                    pyjs_dir=None,
                    cache_dir=None,
                    use_cache=False,
                    host_work_dir=None,
                    backend_kwargs=backend_kwargs_factory(),
                )

    os.chdir(old_cwd)
