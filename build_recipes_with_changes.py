from boa.core.monkeypatch import *
from boa.core.run_build import run_build
import subprocess
import os
import json
import warnings

from collections import OrderedDict

from dataclasses import dataclass, field

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
    target: str
    recipe_dir: str = ""
    command: str = "build"
    features: list[str] = field(default_factory=list)
    variant_config_files: list[str] = field(default_factory=list)
    target_platform: str = ""
    skip_existing: str = "default"


def boa_build(recipes_dir, recipe_name, platform):
    recipe_dir = os.path.join(recipes_dir, recipe_name)
    build_args = BuildArgs(recipe_dir)
    if platform:
        build_args.target_platform = platform
    run_build(build_args)


def test_package(recipes_dir, recipe_name):
    recipe_dir = os.path.join(recipes_dir, recipe_name)
    print(f"Test recipe dir: {recipe_dir}")
    node_test_package(recipe_dir)
    browser_test_package(recipe_dir)


from typing import List, Optional
import typer

app = typer.Typer()


@app.command()
def build_recipes_with_changes(
    recipes_dir, old, new, dryrun: Optional[bool] = typer.Option(False)
):

    recipes_with_changes_per_subdir = find_recipes_with_changes(old=old, new=new)
    print(f"{recipes_with_changes_per_subdir=}")

    for subdir, recipe_with_changes in recipes_with_changes_per_subdir.items():
        for recipe_with_change in recipe_with_changes:

            recipe_dir = os.path.join(recipes_dir, subdir, recipe_with_change)
            if os.path.isdir(recipes_dir):
                if not dryrun:
                    boa_build(
                        recipes_dir=os.path.join(recipes_dir, subdir),
                        recipe_name=recipe_with_change,
                        platform=RECIPES_SUBDIR_MAPPING[subdir],
                    )

                    test_package(
                        recipes_dir=os.path.join(recipes_dir, subdir),
                        recipe_name=recipe_with_change,
                    )

                else:
                    # pass
                    print(f"dryrun build: {os.path.join(subdir,recipe_with_change)}")
            else:
                warnings.warn(f"skipping nonexisting dir {recipe_dir}")


if __name__ == "__main__":
    app()
