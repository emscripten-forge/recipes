import platform 
import os
import subprocess
from .constants import RATTLER_CONDA_BUILD_CONFIG_PATH


def build_with_rattler(recipe=None, recipes_dir=None, emscripten_wasm32=False, skip_existing="local"):

    cmd = ["rattler-build", "build", "--package-format", "tar-bz2"]

    # build single recipe or all recipes in a directory ?
    if recipe is not None and recipes_dir is not None:
        raise ValueError("recipe and recipes_dir cannot be both set")
    elif recipe is None and recipes_dir is None:
        raise ValueError("recipe or recipes_dir must be set")
    elif recipe is not None:
        cmd.extend(["--recipe", str(recipe)])
    elif recipes_dir is not None:
        cmd.extend(["--recipe-dir", str(recipes_dir)])
    
    cmd.extend(["--skip-existing", skip_existing])

    # build for emscripten-wasm32?
    if emscripten_wasm32:
        cmd.extend(["--target-platform", "emscripten-wasm32"])
        # cmd.extend(["--variant-config", str(VARIANT_CONFIG_PATH)]) 

    cmd.extend(["-m", RATTLER_CONDA_BUILD_CONFIG_PATH])
    
    # add conda forge and emscripten-forge channels
    cmd.extend([
        "-c", "https://repo.mamba.pm/emscripten-forge",
        "-c", "conda-forge",
        "-c", "microsoft",
    ])

    # pass existing env vars to subprocess
    print(f"Running rattler-build with command: {cmd}")


    ret = subprocess.run(' '.join(cmd), check=False, shell=True)#, env=os.environ)
    if ret.returncode != 0:
        raise RuntimeError(f"rattler-build failed with return code {ret.returncode}")
    


