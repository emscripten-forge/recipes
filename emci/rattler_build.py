import platform
import os
import subprocess
from pathlib import Path
from .constants import RATTLER_CONDA_BUILD_CONFIG_PATH
import signal

class BuildTimeoutError(Exception):
    def __init__(self, message):
        super().__init__(message)

def build_with_rattler(recipe=None, recipes_dir=None, target_platform=None, 
                       skip_existing="local", continue_on_failure=False, 
                       output_dir=None, timeout=None, format='conda',
                       log_style='simple'):

    cmd = ["rattler-build", "build", "--package-format", format, "--log-style", log_style]

    # build single recipe or all recipes in a directory ?
    if recipe is not None and recipes_dir is not None:
        raise ValueError("recipe and recipes_dir cannot be both set")
    elif recipe is None and recipes_dir is None:
        raise ValueError("recipe or recipes_dir must be set")
    elif recipe is not None:
        cmd.extend(["--recipe", str(recipe)])
    elif recipes_dir is not None:
        cmd.extend(["--recipe-dir", str(recipes_dir)])
        recipes_path = Path(recipes_dir)
        if recipes_path.is_dir():
            folder_names = {p.name for p in recipes_path.iterdir() if p.is_dir()}

    cmd.extend(["--skip-existing", skip_existing])

    # build for emscripten-wasm32?
    if target_platform is not None:
        cmd.extend(["--target-platform", str(target_platform)])
        # cmd.extend(["--variant-config", str(VARIANT_CONFIG_PATH)])

    cmd.extend(["-m", RATTLER_CONDA_BUILD_CONFIG_PATH])

    # add conda forge and emscripten-forge channels
    cmd.extend([
        "-c", "https://repo.prefix.dev/emscripten-forge-bot/emscripten-forge-6x",
        "-c", "conda-forge",
        "-c", "bioconda"
    ])

    # pass existing env vars to subprocess
    print(f"Running rattler-build with command: {cmd}")

    if continue_on_failure:
        cmd.append("--continue-on-failure")

    if output_dir is not None:
        cmd.extend(["--output-dir", str(output_dir)])
        
    # start_new_session=True  →  the child becomes the leader of a new process group
    proc = subprocess.Popen(
        cmd,
        env=os.environ,
        start_new_session=True,          # critical
    )

    try:
        ret = proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired as e:
        # kill the whole process group (negative PID = process group)
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
        except ProcessLookupError:
            pass  # already gone
        # wait a bit so the kernel reaps everything
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            pass
        raise BuildTimeoutError(
            f"rattler-build timed out after {timeout} seconds "
            f"(process group killed)"
        ) from None

    if ret != 0:
        raise RuntimeError(f"rattler-build failed with return code {ret}")
    return proc

