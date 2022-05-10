# from git import Repo


# repo = Repo("/home/derthorsten/src/emscripten-forge/recipes")
# assert not repo.bare
# hcommit = repo.head.commit

# for diff_added in hcommit.diff("HEAD^").iter_change_type("A"):
#     print(diff_addevd)

from boa.core.monkeypatch import *
from boa.core.run_build import run_build
import subprocess
import os
import json

from dataclasses import dataclass, field

from testing.browser_test_package import test_package as browser_test_package
from testing.node_test_package import test_package as node_test_package


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
        print(len(error_str))

    files_with_changes = output_str.splitlines()
    return files_with_changes


def find_recipes_with_changes(old, new):

    files_with_changes = find_files_with_changes(old=old, new=new)
    recipes_with_changes = set()
    for file_with_change in files_with_changes:
        if file_with_change.startswith("recipes/"):
            file_with_change = file_with_change[len("recipes/") :]
            file_with_change = os.path.normpath(file_with_change)
            recipe = file_with_change.split(os.sep)[0]
            recipes_with_changes.add(recipe)

    recipes_with_changes = sorted(list(recipes_with_changes))
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
    print(f"build {recipe_name} for {platform} ")
    platform_args = {"host": ["--target-platform=emscripten-32"], "build": []}[platform]
    recipe_dir = os.path.join(recipes_dir, recipe_name)
    print(recipe_dir)
    build_args = BuildArgs(recipe_dir)
    if platform == "host":
        build_args.target_platform = "emscripten-32"
    run_build(build_args)


def test_package(recipes_dir, recipe_name):
    recipe_dir = os.path.join(recipes_dir, recipe_name)

    node_test_package(recipe_dir)
    browser_test_package(recipe_dir)


def build_recipes_with_changes(old, new, recipes_dir):

    recipes_with_changes = find_recipes_with_changes(old=old, new=new)

    with open("package_platforms.json") as f:
        data = json.load(f)
    data_dict = {}
    for platform, pkgs in data.items():
        data_dict[platform] = set(pkgs)

    for recipe_with_change in recipes_with_changes:

        for platform, pkgs in data_dict.items():
            if recipe_with_change in pkgs:

                boa_build(
                    recipes_dir=recipes_dir,
                    recipe_name=recipe_with_change,
                    platform=platform,
                )

                test_package(
                    recipes_dir=recipes_dir,
                    recipe_name=recipe_with_change,
                )


if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("recipes_dir")
    parser.add_argument("old")
    parser.add_argument("new")
    args = parser.parse_args()
    build_recipes_with_changes(old=args.old, new=args.new, recipes_dir=args.recipes_dir)

    sys.exit(0)
