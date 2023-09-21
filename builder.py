from boa.core.monkeypatch import *
from boa.core.run_build import run_build
from boa.pyapi import py_build

import subprocess
import os
import json
import warnings
import tempfile
import rich
from collections import OrderedDict
import functools
import tempfile
import shutil
import empack
import glob
from testing.package_testing import test_package as test_package_impl
from empack.file_patterns import pkg_file_filter_from_yaml
from contextlib import contextmanager
from mamba.utils import init_api_context
import libmambapy as api

from pathlib import Path

RECIPES_SUBDIR_MAPPING = OrderedDict(
    [("recipes", ""), ("recipes_emscripten", "emscripten-wasm32")]
)

THIS_DIR = os.path.dirname(os.path.realpath(__file__))
CONFIG_PATH = os.path.join(THIS_DIR, "empack_config.yaml")
PKG_FILE_FILTER = pkg_file_filter_from_yaml(CONFIG_PATH)


CONDA_PREFIX = os.environ.get("CONDA_PREFIX")
if CONDA_PREFIX is None:
    raise RuntimeError(
        "environment varialbe `CONDA_PREFIX` is not set but needed to run this script"
    )
CONDA_BLD_DIR = os.path.join(CONDA_PREFIX, "conda-bld")
Path(CONDA_BLD_DIR).mkdir(exist_ok=True)

from typing import List, Optional
import typer
import rich

app = typer.Typer(pretty_exceptions_show_locals=False)
build_app = typer.Typer()
app.add_typer(build_app, name="build")

# check if a pkg exists 
def is_existing_pkg(pkg_name):
    channels = (
        f" -c https://repo.mamba.pm/emscripten-forge -c conda-forge "
    )

    cmd = [
        f"""$MAMBA_EXE  create -n name_does_not_matter_here {channels} {pkg_name} --dry-run --no-deps --platform=emscripten-wasm32"""
    ]

    ret = subprocess.run(cmd, shell=True)
    #  stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    returncode = ret.returncode
    return returncode == 0




@contextmanager
def restore_cwd():
    base_work_dir = os.getcwd()
    yield
    os.chdir(base_work_dir)


def find_files_with_changes(old, new):
    cmd = ["git", "diff", "--name-only", old, new]
    result = subprocess.run(
        cmd,
        shell=False,
        check=True,
        capture_output=True,
    )
    output_str = result.stdout.decode()
    error_str = result.stderr.decode()
    if len(error_str):
        print(error_str)

    files_with_changes = output_str.splitlines()
    # print(files_with_changes)
    return files_with_changes


def find_recipes_with_changes(old, new):
    files_with_changes = find_files_with_changes(old=old, new=new)

    recipes_with_changes = {k: set() for k in RECIPES_SUBDIR_MAPPING.keys()}
    # print("recipes_with_changes", recipes_with_changes)
    for subdir in RECIPES_SUBDIR_MAPPING.keys():
        for file_with_change in files_with_changes:
            if file_with_change.startswith(f"recipes/{subdir}/"):
                # print(file_with_change)
                file_with_change = file_with_change[len(f"recipes/{subdir}/") :]
                file_with_change = os.path.normpath(file_with_change)
                recipe = file_with_change.split(os.sep)[0]
                recipes_with_changes[subdir].add(recipe)

    for subdir in RECIPES_SUBDIR_MAPPING.keys():
        recipes_with_changes[subdir] = sorted(list(recipes_with_changes[subdir]))
    return recipes_with_changes


def test_package(recipe, work_dir):
    # recipe_dir = os.path.join(recipes_dir, recipe_name)
    print(f"Test recipe: {recipe} in work_dir: {work_dir}")
    test_package_impl(recipe=recipe, work_dir=work_dir, conda_bld_dir=CONDA_BLD_DIR)


def cleanup():
    do_not_delete = ["noarch", "linux-64", "emscripten-wasm32", "icons"]
    do_not_delete = [os.path.join(CONDA_BLD_DIR, d) for d in do_not_delete]

    for dirname in glob.iglob(os.path.join(CONDA_BLD_DIR, "**"), recursive=False):
        if os.path.isdir(dirname):
            if dirname not in do_not_delete and "_" in dirname:
                shutil.rmtree(dirname)


def post_build_callback(
    recipe, target_platform, sorted_outputs, final_names, skip_tests, work_dir
):
    if target_platform == "emscripten-wasm32" and (not skip_tests):
        with restore_cwd():
            test_package(recipe=recipe, work_dir=work_dir)
    cleanup()


def boa_build(
    work_dir,
    platform,
    target=None,
    recipe_dir=None,
    skip_tests=False,
    skip_existing=False,
):
    target_platform = None
    if platform:
        target_platform = platform
    str_skip_existing = "default"
    if skip_existing:
        str_skip_existing = "yes"

    cb = functools.partial(
        post_build_callback, skip_tests=skip_tests, work_dir=work_dir
    )

    py_build(
        target=target,
        recipe_dir=recipe_dir,
        target_platform=target_platform,
        skip_existing=str_skip_existing,
        post_build_callback=cb,
    )
    os.chdir(work_dir)


@build_app.command()
def directory(
    recipes_dir,
    emscripten_wasm32: Optional[bool] = typer.Option(False),
    skip_tests: Optional[bool] = typer.Option(False),
    skip_existing: Optional[bool] = typer.Option(False),
):
    work_dir = os.getcwd()
    platform = ""
    if emscripten_wasm32:
        platform = "emscripten-wasm32"
    boa_build(
        work_dir=work_dir,
        target=recipes_dir,
        recipe_dir=None,
        platform=platform,
        skip_tests=skip_tests,
        skip_existing=skip_existing,
    )


@build_app.command()
def explicit(
    recipe_dir,
    emscripten_wasm32: Optional[bool] = typer.Option(False),
    skip_tests: Optional[bool] = typer.Option(False),
    skip_existing: Optional[bool] = typer.Option(True),
):
    work_dir = os.getcwd()
    assert os.path.isdir(recipe_dir), f"{recipe_dir} is not a dir"
    platform = ""
    if emscripten_wasm32:
        print("WITH EM")
        platform = "emscripten-wasm32"
    boa_build(
        work_dir=work_dir,
        target=recipe_dir,
        platform=platform,
        skip_tests=skip_tests,
        skip_existing=skip_existing,
    )


@build_app.command()
def changed(
    root_dir,
    old,
    new,
    dryrun: Optional[bool] = typer.Option(False),
    skip_tests: Optional[bool] = typer.Option(False),
    skip_existing: Optional[bool] = typer.Option(False),
):
    work_dir = os.getcwd()
    recipes_dir = os.path.join(root_dir, "recipes")
    recipes_with_changes_per_subdir = find_recipes_with_changes(old=old, new=new)
    rich.pretty.pprint(recipes_with_changes_per_subdir)

    for subdir, recipe_with_changes in recipes_with_changes_per_subdir.items():
        # create a  temp dir and copy all changed recipes
        # to that dir (because Then we can let boa do the
        # topological sorting)
        with tempfile.TemporaryDirectory() as tmp_folder_root:
            tmp_recipes_root_str = os.path.join(
                tmp_folder_root, "recipes", "recipes_per_platform"
            )
            os.makedirs(tmp_folder_root, exist_ok=True)

            for recipe_with_change in recipe_with_changes:

                if True and RECIPES_SUBDIR_MAPPING[subdir] == "emscripten-wasm32":
                    pkg_name = recipe_with_change
                    print(f"Check if pkg exists: {pkg_name}")
                    if is_existing_pkg(pkg_name):
                        print(f"Skip existing pkg: {pkg_name}")
                        continue
                    else:
                        print(f"Build pkg: {pkg_name}")
                recipe_dir = os.path.join(recipes_dir, subdir, recipe_with_change)

                # diff can shown deleted recipe as changed
                if os.path.isdir(recipe_dir):
                    tmp_recipe_dir = os.path.join(
                        tmp_recipes_root_str, recipe_with_change
                    )
                    # os.mkdir(tmp_recipe_dir)
                    shutil.copytree(recipe_dir, tmp_recipe_dir)

            print([x[0] for x in os.walk(tmp_recipes_root_str)])
            
            boa_build(
                work_dir=work_dir,
                target=tmp_recipes_root_str,
                recipe_dir=None,
                platform=RECIPES_SUBDIR_MAPPING[subdir],
                skip_tests=skip_tests,
                skip_existing=skip_existing,
            )


if __name__ == "__main__":
    app()
