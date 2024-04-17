import os
from collections import OrderedDict
from pathlib import Path


RECIPES_SUBDIR_MAPPING = OrderedDict(
    [("recipes", ""), ("recipes_emscripten", "emscripten-wasm32")]
)


THIS_DIR = os.path.dirname(os.path.realpath(__file__))
REPO_ROOT = Path(THIS_DIR).parents[0].resolve()
RECIPES_ROOT = REPO_ROOT / "recipes"
RECIPES_EMSCRIPTEN_DIR = RECIPES_ROOT / "recipes_emscripten"
CONFIG_PATH = os.path.join(REPO_ROOT, "empack_config.yaml")


# rattler build related
RATTLER_CONDA_BUILD_CONFIG_PATH = os.path.join(REPO_ROOT, "rattler_conda_build_config.yaml")

# env var to force the use of boa instead of rattler for  testing the legacy build system
FORCE_BOA = bool(int(os.environ.get("FORCE_BOA", False)))
FORCE_RATTLER = bool(int(os.environ.get("FORCE_RATTLER", False)))

if FORCE_BOA and FORCE_RATTLER:
    raise ValueError("FORCE_BOA and FORCE_RATTLER cannot be both set")

CONDA_PREFIX = os.environ.get("CONDA_PREFIX")
if CONDA_PREFIX is None:
    raise RuntimeError(
        "environment varialbe `CONDA_PREFIX` is not set but needed to run this script"
    )
CONDA_BLD_DIR = os.path.join(CONDA_PREFIX, "conda-bld")
Path(CONDA_BLD_DIR).mkdir(exist_ok=True)
