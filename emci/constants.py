import os
from collections import OrderedDict
from pathlib import Path

THIS_DIR = os.path.dirname(os.path.realpath(__file__))
REPO_ROOT = Path(THIS_DIR).parents[0].resolve()
RECIPES_ROOT = REPO_ROOT / "recipes"
RECIPES_EMSCRIPTEN_DIR = RECIPES_ROOT / "recipes_wasm"


# rattler build related
RATTLER_CONDA_BUILD_CONFIG_PATH = os.path.join(REPO_ROOT, "variant.yaml")

CONDA_PREFIX = os.environ.get("CONDA_PREFIX")
if CONDA_PREFIX is None:
    raise RuntimeError(
        "environment varialbe `CONDA_PREFIX` is not set but needed to run this script"
    )
CONDA_BLD_DIR = os.path.join(CONDA_PREFIX, "conda-bld")
Path(CONDA_BLD_DIR).mkdir(exist_ok=True)

DEFAULT_EMSCRIPTEN_FORGE_CHANNEL = "emscripten-forge-bot/emscripten-forge-6x"