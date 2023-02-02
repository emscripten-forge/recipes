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

RECIPES_SUBDIR_MAPPING = OrderedDict(
    [("recipes", ""), ("recipes_emscripten", "emscripten-32")]
)

THIS_DIR = os.path.dirname(os.path.realpath(__file__))
CONFIG_PATH = os.path.join(THIS_DIR, "empack_config.yaml")
PKG_FILE_FILTER = pkg_file_filter_from_yaml(CONFIG_PATH)


from typing import List, Optional
import typer
import rich 
app = typer.Typer(pretty_exceptions_show_locals=False)
build_app = typer.Typer()
app.add_typer(build_app, name="build")


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


def test_package(recipe):
    # recipe_dir = os.path.join(recipes_dir, recipe_name)
    print(f"Test recipe: {recipe}")
    test_package_impl(recipe=recipe)


def cleanup():
    prefix = os.environ["CONDA_PREFIX"]
    conda_bld_dir = os.path.join(prefix, "conda-bld")

    do_not_delete = ["noarch", "linux-64", "emscripten-32", "icons"]
    do_not_delete = [os.path.join(conda_bld_dir, d) for d in do_not_delete]

    for dirname in glob.iglob(os.path.join(conda_bld_dir, "**"), recursive=False):
        if os.path.isdir(dirname):
            if dirname not in do_not_delete and "_" in dirname:
                shutil.rmtree(dirname)


def post_build_callback(
    recipe, target_platform, sorted_outputs, final_names, skip_tests
):

    if target_platform == "emscripten-32" and (not skip_tests):
        with restore_cwd():
            test_package(recipe)
    cleanup()


def boa_build(
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

    base_work_dir = os.getcwd()

    cb = functools.partial(post_build_callback, skip_tests=skip_tests)

    py_build(
        target=target,
        recipe_dir=recipe_dir,
        target_platform=target_platform,
        skip_existing=str_skip_existing,
        post_build_callback=cb,
    )
    os.chdir(base_work_dir)


@build_app.command()
def directory(
    recipes_dir,
    emscripten_32: Optional[bool] = typer.Option(False),
    skip_tests: Optional[bool] = typer.Option(False),
    skip_existing: Optional[bool] = typer.Option(False),
):
    # assert os.path.isdir(recipe_dir), f"{recipe_dir} is not a dir"
    platform = ""
    if emscripten_32:
        platform = "emscripten-32"
    boa_build(
        target=recipes_dir,
        recipe_dir=None,
        platform=platform,
        skip_tests=skip_tests,
        skip_existing=skip_existing,
    )


@build_app.command()
def explicit(
    recipe_dir,
    emscripten_32: Optional[bool] = typer.Option(False),
    skip_tests: Optional[bool] = typer.Option(False),
    skip_existing: Optional[bool] = typer.Option(False),
):
    assert os.path.isdir(recipe_dir), f"{recipe_dir} is not a dir"
    platform = ""
    if emscripten_32:
        print("WITH EM")
        platform = "emscripten-32"
    boa_build(
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
    base_work_dir = os.getcwd()
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
                target=tmp_recipes_root_str,
                recipe_dir=None,
                platform=RECIPES_SUBDIR_MAPPING[subdir],
                skip_tests=skip_tests,
                skip_existing=skip_existing,
            )


if __name__ == "__main__":
    app()
