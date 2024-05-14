from .rattler_build import build_with_rattler
from .constants import RECIPES_SUBDIR_MAPPING, RECIPES_EMSCRIPTEN_DIR
from .find_recipes_with_changes import find_recipes_with_changes

import sys
import os
import tempfile
import shutil
from pathlib import Path

from typing import Optional
import typer

app = typer.Typer(pretty_exceptions_enable=False)
build_app = typer.Typer()
app.add_typer(build_app, name="build")


@build_app.command()
def changed(
    root_dir,
    old,
    new,
    dryrun: Optional[bool] = typer.Option(False),
    skip_tests: Optional[bool] = typer.Option(False),
    skip_existing: Optional[bool] = typer.Option(True)
):
    work_dir = os.getcwd()
    recipes_dir = os.path.join(root_dir, "recipes")
    recipes_with_changes_per_subdir = find_recipes_with_changes(old=old, new=new)

    for subdir, recipe_with_changes in recipes_with_changes_per_subdir.items():
        if len(recipe_with_changes) == 0:
            continue
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
           
            # delete all potential "recipe_legacy.yaml" files
            for root, dirs, files in os.walk(tmp_recipes_root_str):
                for file in files:
                    if file == "recipe_legacy.yaml":
                        os.remove(os.path.join(root, file))
            build_with_rattler(recipe=None, recipes_dir=tmp_recipes_root_str, emscripten_wasm32=RECIPES_SUBDIR_MAPPING[subdir] == "emscripten-wasm32")


bot_app = typer.Typer()
app.add_typer(bot_app, name="bot")


@bot_app.command()
def bump_recipes_versions():
    from .bot.bump_recipes_versions import bump_recipe_versions

    bump_recipe_versions(RECIPES_EMSCRIPTEN_DIR)

if __name__ == "__main__":
    app()
