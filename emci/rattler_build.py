import platform
import os
import subprocess
from pathlib import Path
from .constants import RATTLER_CONDA_BUILD_CONFIG_PATH
import signal

class BuildTimeoutError(Exception):
    def __init__(self, message):
        super().__init__(message)



try:
    import psutil
except ImportError:
    raise ImportError("pip install psutil  # required for reliable process-tree kill")


def kill_proc_tree(pid, sig=signal.SIGTERM, include_parent=True, timeout=5):
    """Recursively kill a process tree reliably, catching newly spawned children."""
    try:
        parent = psutil.Process(pid)
    except psutil.NoSuchProcess:
        return

    # Grab initial process hierarchy
    procs = parent.children(recursive=True)
    if include_parent:
        procs.append(parent)

    # Step 1: Send initial signal (SIGTERM preferred to allow clean shutdown)
    for p in procs:
        try:
            p.send_signal(sig)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass

    # Step 2: Wait briefly for processes to terminate
    gone, alive = psutil.wait_procs(procs, timeout=timeout)

    # Step 3: Re-scan for any newly spawned children that escaped the first round
    if parent.is_running():
        try:
            extra_children = parent.children(recursive=True)
            alive.extend([c for c in extra_children if c not in alive])
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass

    # Step 4: Forcefully SIGKILL remaining process tree (bottom-up)
    for p in reversed(alive):
        try:
            p.kill()  # SIGKILL
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass

    # Final wait to reap processes
    psutil.wait_procs(alive, timeout=3)



def build_with_rattler(recipe=None, recipes_dir=None, target_platform=None, 
                       skip_existing="local", continue_on_failure=False, 
                       output_dir=None, timeout=None, format='tar-bz2',
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
        
    proc = subprocess.Popen(
            cmd,
            env=os.environ,
            # still useful, but not sufficient by itself
            start_new_session=True,
        )

    try:
        ret = proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        print(f"Timeout of {timeout}s reached – killing process tree (pid={proc.pid})")
        kill_proc_tree(proc.pid, sig=signal.SIGKILL)
        # make sure the Popen object is reaped
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            pass
        raise BuildTimeoutError(f"rattler-build timed out after {timeout} seconds") from None

    if ret != 0:
        raise RuntimeError(f"rattler-build failed with return code {ret}")
    return proc