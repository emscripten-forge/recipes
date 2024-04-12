# this contains monkey patches for boa and needs to be imported early
has_boa = False
import warnings
try:
    from .deprecated.boa_build import build_package_with_boa
    has_boa = True
except ImportError:
    warnings.warn("boa_build module not found. This is fine if you only build with rattler-build")


from .rattler_build import build_with_rattler


from .constants import RECIPES_SUBDIR_MAPPING, FORCE_BOA, RECIPES_EMSCRIPTEN_DIR
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
        platform = "emscripten-wasm32"

    # check if package dir containers a rattler_recipe.yaml
    # if so, we need to build the package with rattler
    # otherwise we can use boa
        
    rattler_recipe_file = os.path.join(Path(recipe_dir).resolve(), "rattler_recipe.yaml")
    if os.path.isfile(rattler_recipe_file) and not FORCE_BOA:

        rattler_recipe = Path(recipe_dir) / "rattler_recipe.yaml"
        build_with_rattler(recipe=rattler_recipe, emscripten_wasm32=emscripten_wasm32)
        
    else:
        if not has_boa:
            raise RuntimeError("boa_build module not found. This is required to build boa recipes")
        # show deprecated warning
        warnings.warn("Building with boa is deprecated. Please use rattler instead.")

        build_package_with_boa(
            work_dir=work_dir,
            target=recipe_dir,
            platform=platform,
            skip_tests=skip_tests,
            skip_existing=skip_existing,
        )

def check_recipes_format(recipes_dir):
    all_rattler = True
    all_boa = True
    for recipe in recipes_dir:
        # check if there is a rattler_recipe.yaml file
        rattler_recipe_file = os.path.join(Path(recipe).resolve(), "rattler_recipe.yaml")
        if not os.path.isfile(rattler_recipe_file):
            all_rattler = False
        
        boa_recipe_file = os.path.join(Path(recipe).resolve(), "recipe.yaml")
        if not os.path.isfile(boa_recipe_file):
            all_boa = False
            
    return all_rattler, all_boa


@build_app.command()
def changed(
    root_dir,
    old,
    new,
    dryrun: Optional[bool] = typer.Option(False),
    skip_tests: Optional[bool] = typer.Option(False),
    skip_existing: Optional[bool] = typer.Option(True),
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


            changed_recipes_dirs = [os.path.join(recipes_dir, subdir, recipe_with_change) for recipe_with_change in recipe_with_changes]
            all_rattler, all_boa = check_recipes_format(changed_recipes_dirs)
            if not all_rattler and not all_boa:
                raise RuntimeError("All recipes must be in the same format (rattler or boa)")


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
            
            if all_boa and (not all_rattler or FORCE_BOA):
                if not has_boa:
                    raise RuntimeError("boa_build module not found. This is required to build boa recipes")
                # delete all potential "rattler_recipe.yaml" files
                for root, dirs, files in os.walk(tmp_recipes_root_str):
                    for file in files:
                        if file == "rattler_recipe.yaml":
                            os.remove(os.path.join(root, file))
                warnings.warn("Building with boa is deprecated. Please use rattler instead.")
                build_package_with_boa(
                    work_dir=work_dir,
                    target=tmp_recipes_root_str,
                    recipe_dir=None,
                    platform=RECIPES_SUBDIR_MAPPING[subdir],
                    skip_tests=skip_tests,
                    skip_existing=skip_existing,
                )
            elif all_rattler:
                # delete all potential "recipe.yaml" files
                for root, dirs, files in os.walk(tmp_recipes_root_str):
                    for file in files:
                        if file == "recipe.yaml":
                            os.remove(os.path.join(root, file))
                # rename all rattler_recipe.yaml files to recipe.yaml
                for root, dirs, files in os.walk(tmp_recipes_root_str):
                    for file in files:
                        if file == "rattler_recipe.yaml":
                            os.rename(os.path.join(root, file), os.path.join(root, "recipe.yaml"))

                build_with_rattler(recipe=None, recipes_dir=tmp_recipes_root_str, emscripten_wasm32=RECIPES_SUBDIR_MAPPING[subdir] == "emscripten-wasm32")

            else:
                raise RuntimeError("All recipes must be in the same format (rattler or boa)")



bot_app = typer.Typer()
app.add_typer(bot_app, name="bot")


@bot_app.command()
def bump_recipes_versions():
    from .bot.bump_recipes_versions import bump_recipe_versions

    bump_recipe_versions(RECIPES_EMSCRIPTEN_DIR)

if __name__ == "__main__":
    app()
