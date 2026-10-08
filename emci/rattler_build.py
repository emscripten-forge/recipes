import os
import signal
import platform
import subprocess

class BuildTimeoutError(Exception):
    def __init__(self, message):
        super().__init__(message)


def kill_proc_group(pid):
    """Force-kills the process and all child processes created under its group."""
    if platform.system() == "Windows":
        # /F = Force, /T = Tree (kill all child processes)
        subprocess.run(["taskkill", "/F", "/T", "/PID", str(pid)], capture_output=True)
    else:
        try:
            pgid = os.getpgid(pid)
            os.killpg(pgid, signal.SIGKILL)
        except (ProcessLookupError, PermissionError):
            pass

def build_with_rattler(recipe=None, recipes_dir=None, target_platform=None, 
                       skip_existing="local", continue_on_failure=False, 
                       output_dir=None, timeout=None, format='tar-bz2',
                       log_style='simple'):

    cmd = ["rattler-build", "build", "--package-format", format, "--log-style", log_style]

    if recipe is not None and recipes_dir is not None:
        raise ValueError("recipe and recipes_dir cannot be both set")
    elif recipe is None and recipes_dir is None:
        raise ValueError("recipe or recipes_dir must be set")
    elif recipe is not None:
        cmd.extend(["--recipe", str(recipe)])
    elif recipes_dir is not None:
        cmd.extend(["--recipe-dir", str(recipes_dir)])

    cmd.extend(["--skip-existing", skip_existing])

    if target_platform is not None:
        cmd.extend(["--target-platform", str(target_platform)])

    cmd.extend(["-m", RATTLER_CONDA_BUILD_CONFIG_PATH])
    cmd.extend([
        "-c", "https://repo.prefix.dev/emscripten-forge-bot/emscripten-forge-6x",
        "-c", "conda-forge",
        "-c", "bioconda"
    ])

    if continue_on_failure:
        cmd.append("--continue-on-failure")

    if output_dir is not None:
        cmd.extend(["--output-dir", str(output_dir)])

    print(f"Running rattler-build with command: {cmd}")

    # Set up process group flags based on OS
    kwargs = {"env": os.environ}
    if platform.system() == "Windows":
        kwargs["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP
    else:
        kwargs["start_new_session"] = True

    proc = subprocess.Popen(cmd, **kwargs)

    try:
        ret = proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        print(f"\nTimeout of {timeout}s reached – force killing process group (pid={proc.pid})...")
        kill_proc_group(proc.pid)
        proc.wait()
        raise BuildTimeoutError(f"rattler-build timed out after {timeout} seconds") from None
    except KeyboardInterrupt:
        print(f"\nCtrl+C detected – force killing rattler-build process group (pid={proc.pid})...")
        kill_proc_group(proc.pid)
        proc.wait()
        raise  # Re-raise KeyboardInterrupt to terminate Python caller cleanly

    if ret != 0:
        raise RuntimeError(f"rattler-build failed with return code {ret}")
    return proc