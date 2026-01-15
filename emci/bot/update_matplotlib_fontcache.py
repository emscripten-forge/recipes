from subprocess import run as subprocess_run
import pyjs_code_runner
import socket
from contextlib import closing, contextmanager, redirect_stdout
import os
from pyjs_code_runner.run import run
from pyjs_code_runner.backend.backend import BackendType
from pyjs_code_runner.get_file_filter import get_file_filter
from pathlib import Path
import shutil
import sys
import json
import yaml
import pprint
import io


THIS_DIR = Path(os.getcwd())
MAIN_MOUNT_DIR = Path(THIS_DIR) / "main_mount"
PREFIX_PATH = THIS_DIR / "prefix"

START_MARKER = "/// BEGIN FONTCACHE"
END_MARKER = "/// END FONTCACHE"

PYTHON_FILENAME = "generate_fontcache.py"
PYTHON_CODE = f"""
import matplotlib
from pathlib import Path

# This import is the one triggering the font cache building
import matplotlib.pyplot

print('{START_MARKER}')
with open(Path(matplotlib.__file__).parent / "fontlist.json") as fd:
    print(fd.read())
print('{END_MARKER}')
"""


def find_free_port():
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as s:
        s.bind(("", 0))
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        return s.getsockname()[1]


def update_matplotlib_fontcache(recipe_dir):
    matplotlib_folder = Path(recipe_dir) / "matplotlib"
    recipe_file = matplotlib_folder / "recipe.yaml"
    fontlist_file = matplotlib_folder / "src" / "fontlist.json"

    # Get current font list version
    with open(fontlist_file, "r") as fobj:
        fontlist = json.load(fobj)
    current_fontlist_version = fontlist["_version"]

    # Read current matplotlib version
    with open(recipe_file) as stream:
        recipe = yaml.safe_load(stream)
    matplotlib_version = recipe["context"]["version"]

    # Create prefix with installing pyjs and matplotlib = _x
    subprocess_run(
        [
            "micromamba",
            "create",
            "--yes",
            "--prefix",
            PREFIX_PATH,
            "--platform=emscripten-wasm32",
            "-c",
            "https://prefix.dev/emscripten-forge-dev",
            "-c",
            "https://prefix.dev/conda-forge",
            f"matplotlib={matplotlib_version}",
            "pyjs"
        ],
        check=True
    )

    virtual_work_dir = Path("/")

    # Create runnable script in to mount in the emscripten fs
    MAIN_MOUNT_DIR.mkdir(exist_ok=True)
    with open(MAIN_MOUNT_DIR / PYTHON_FILENAME, "w") as fobj:
        fobj.write(PYTHON_CODE)

    buffer = io.StringIO()
    with redirect_stdout(buffer):
        run(
            conda_env=PREFIX_PATH,
            relocate_prefix="/",
            backend_type=BackendType.browser_main,
            script=PYTHON_FILENAME,
            async_main=False,
            mounts=[
                (MAIN_MOUNT_DIR, virtual_work_dir)
            ],
            work_dir=virtual_work_dir,
            pyjs_dir=None,
            cache_dir=None,
            use_cache=False,
            host_work_dir=None,
            backend_kwargs=(lambda: dict(port=find_free_port(), slow_mo=1, headless=True))(),
        )
    output = buffer.getvalue()

    # Cleanup
    shutil.rmtree(MAIN_MOUNT_DIR)
    shutil.rmtree(PREFIX_PATH)

    start = text.find(start_marker)
    end = text.find(end_marker)

    if start == -1 or end == -1:
        raise ValueError("Fontcache markers not found in the output")

    start += len(start_marker)

    new_fontlist = json.loads(text[start:end].strip())

    if new_fontlist["_version"] == current_fontlist_version:
        print('Matplotlib fontlist is already up-to-date, nothing to do')
        return

    # TODO if fontcache version has changed
    # TODO   - bump recipe build n
    # TODO   - commit and push
