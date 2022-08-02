from boa.core.monkeypatch import *
from boa.core.run_build import run_build
import subprocess
import os
import json
import warnings
import tempfile
import rich
from collections import OrderedDict
import functools
from dataclasses import dataclass, field
import tempfile
import shutil
import empack
import glob
from testing.browser_test_package import test_package as browser_test_package
from testing.node_test_package import test_package as node_test_package

RECIPES_SUBDIR_MAPPING = OrderedDict(
    [("recipes", ""), ("recipes_emscripten", "emscripten-32")]
)


from contextlib import contextmanager


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


@dataclass
class BuildArgs:
    target: str = ""
    recipe_dir: str = ""
    command: str = "build"
    features: list[str] = field(default_factory=list)
    variant_config_files: list[str] = field(default_factory=list)
    target_platform: str = ""
    skip_existing: str = "default"
    post_build_callback: object = None
    output_folder: object = None


def test_package(recipe):
    # recipe_dir = os.path.join(recipes_dir, recipe_name)
    print(f"Test recipe: {recipe}")
    node_test_package(recipe)
    browser_test_package(recipe)


def emscripten_pack_package(recipe):
    pack_conda_pkg(
        recipe=recipe,
    )


def cleanup():
    prefix = os.environ["CONDA_PREFIX"]
    conda_bld_dir = os.path.join(prefix, "conda-bld")

    do_not_delete = ["noarch", "linux-64", "emscripten-32"]
    do_not_delete = [os.path.join(conda_bld_dir, d) for d in do_not_delete]

    for dirname in glob.iglob(os.path.join(conda_bld_dir, "**"), recursive=False):
        if os.path.isdir(dirname):
            if dirname not in do_not_delete:
                print(f"DELETING {dirname}")
                shutil.rmtree(dirname)


def post_build_callback(
    recipe,
    target_platform,
    sorted_outputs,
    final_names,
    pack_prefix,
    pack_outdir,
    skip_tests,
    skip_pack,
):

    # cleanup

    assert len(sorted_outputs) == 1, "only one output per pkg atm"
    rich.pretty.pprint(
        {
            "target_platform": target_platform,
            "recipe": recipe,
            "sorted_outputs": sorted_outputs[0],
            "final_names": final_names[0],
        }
    )
    if target_platform == "emscripten-32" and (not skip_tests):
        with restore_cwd():
            test_package(recipe)

    if target_platform == "emscripten-32":
        with restore_cwd():
            empack.file_packager.pack_conda_pkg(
                recipe=recipe,
                pack_prefix=pack_prefix,
                pack_outdir=pack_outdir,
                outname=final_names[0],
            )

    cleanup()


def boa_build(
    platform,
    pack_prefix,
    pack_outdir,
    target=None,
    recipe_dir=None,
    skip_tests=False,
    skip_pack=False,
    skip_existing=False,
):

    base_work_dir = os.getcwd()
    build_args = BuildArgs()
    if skip_existing:
        build_args.skip_existing = "yes"

    if target is not None:
        build_args.target = target
    if recipe_dir is not None:
        build_args.recipe_dir = recipe_dir

    build_args.post_build_callback = functools.partial(
        post_build_callback,
        skip_tests=skip_tests,
        skip_pack=skip_pack,
        pack_prefix=pack_prefix,
        pack_outdir=pack_outdir,
    )
    if platform:
        build_args.target_platform = platform
    run_build(build_args)
    os.chdir(base_work_dir)


from typing import List, Optional
import typer

app = typer.Typer()


build_app = typer.Typer()
app.add_typer(build_app, name="build")


@build_app.command()
def directory(
    recipes_dir,
    pack_prefix: str,
    pack_outdir: str,
    emscripten_32: Optional[bool] = typer.Option(False),
    skip_tests: Optional[bool] = typer.Option(False),
    skip_pack: Optional[bool] = typer.Option(False),
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
        skip_pack=skip_pack,
        pack_prefix=pack_prefix,
        skip_existing=skip_existing,
        pack_outdir=pack_outdir,
    )


@build_app.command()
def explicit(
    recipe_dir,
    pack_prefix: str,
    pack_outdir: str,
    emscripten_32: Optional[bool] = typer.Option(False),
    skip_tests: Optional[bool] = typer.Option(False),
    skip_pack: Optional[bool] = typer.Option(False),
    skip_existing: Optional[bool] = typer.Option(False),
):
    assert os.path.isdir(recipe_dir), f"{recipe_dir} is not a dir"
    platform = ""
    if emscripten_32:
        platform = "emscripten-32"
    boa_build(
        target=recipe_dir,
        platform=platform,
        skip_tests=skip_tests,
        skip_pack=skip_pack,
        pack_prefix=pack_prefix,
        skip_existing=skip_existing,
        pack_outdir=pack_outdir,
    )


@build_app.command()
def changed(
    root_dir,
    old,
    new,
    pack_prefix: str,
    pack_outdir: str,
    dryrun: Optional[bool] = typer.Option(False),
    skip_tests: Optional[bool] = typer.Option(False),
    skip_pack: Optional[bool] = typer.Option(False),
    skip_existing: Optional[bool] = typer.Option(False),
):
    base_work_dir = os.getcwd()
    recipes_dir = os.path.join(root_dir, "recipes")
    pytest_driver_src_dir = os.path.join(base_work_dir, "testing", "pytest_driver")

    recipes_with_changes_per_subdir = find_recipes_with_changes(old=old, new=new)
    rich.pretty.pprint(recipes_with_changes_per_subdir)

    for subdir, recipe_with_changes in recipes_with_changes_per_subdir.items():

        # create a  temp dir and copy all changed recipes
        # to that dir (because Then we can let boa do the
        # topological sorting
        with tempfile.TemporaryDirectory() as tmp_folder_root:

            tmp_recipes_root_str = os.path.join(
                tmp_folder_root, "recipes", "recipes_per_platform"
            )
            os.makedirs(tmp_folder_root, exist_ok=True)

            tmp_pytest_driver_src_dir = os.path.join(
                tmp_folder_root, "testing", "pytest_driver"
            )
            os.makedirs(tmp_folder_root, exist_ok=True)
            shutil.copytree(pytest_driver_src_dir, tmp_pytest_driver_src_dir)

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
                skip_pack=skip_pack,
                pack_prefix=pack_prefix,
                skip_existing=skip_existing,
                pack_outdir=pack_outdir,
            )


if __name__ == "__main__":
    app()
