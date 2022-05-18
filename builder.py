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

import empack
from testing.browser_test_package import test_package as browser_test_package
from testing.node_test_package import test_package as node_test_package

RECIPES_SUBDIR_MAPPING = OrderedDict(
    [("recipes", ""), ("recipes_emscripten", "emscripten-32")]
)


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


def test_package(recipe):
    # recipe_dir = os.path.join(recipes_dir, recipe_name)
    print(f"Test recipe: {recipe}")
    node_test_package(recipe)
    browser_test_package(recipe)


def emscripten_pack_package(recipe):
    pack_conda_pkg(
        recipe=recipe,
    )


def post_build_callback(
    recipe,
    target_platform,
    sorted_outputs,
    pack_prefix,
    pack_outdir,
    skip_tests,
    skip_pack,
):
    assert len(sorted_outputs) == 1, "only one output per pkg atm"
    rich.pretty.pprint(
        {
            "target_platform": target_platform,
            "recipe": recipe,
            "sorted_outputs": sorted_outputs[0],
        }
    )
    if target_platform == "emscripten-32" and (not skip_tests):
        test_package(recipe)

    if target_platform == "emscripten-32":
        empack.file_packager.pack_conda_pkg(
            recipe=recipe, pack_prefix=pack_prefix, pack_outdir=pack_outdir
        )


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
    print(build_args)
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
    recipes_dir,
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

    recipes_with_changes_per_subdir = find_recipes_with_changes(old=old, new=new)
    rich.pretty.pprint(recipes_with_changes_per_subdir)

    for subdir, recipe_with_changes in recipes_with_changes_per_subdir.items():

        for recipe_with_change in recipe_with_changes:

            recipe_dir = os.path.join(recipes_dir, subdir, recipe_with_change)
            print("THE RECIPE DIR", recipe_dir)
            if os.path.isdir(recipe_dir):
                if not dryrun:
                    boa_build(
                        target=recipe_dir,
                        platform=RECIPES_SUBDIR_MAPPING[subdir],
                        skip_tests=skip_tests,
                        skip_pack=skip_pack,
                        pack_prefix=pack_prefix,
                        pack_outdir=pack_outdir,
                        skip_existing=skip_existing,
                    )

                else:
                    # pass
                    print(f"dryrun build: {os.path.join(subdir,recipe_with_change)}")
            else:
                warnings.warn(f"skipping nonexisting dir {recipe_dir}")


if __name__ == "__main__":
    app()
