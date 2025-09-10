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
import yaml
from pydantic import BaseModel, constr, field_validator

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
def bump_recipes_versions(target_branch_name: str):
    from .bot.bump_recipes_versions import bump_recipe_versions

    bump_recipe_versions(RECIPES_EMSCRIPTEN_DIR, target_branch_name)

# --------------------------
# Pydantic schema definitions
# --------------------------

class Source(BaseModel):
    url: constr(pattern=r"^https://.*\.(tar\.gz|zip)$")
    sha256: constr(pattern=r"^[0-9a-f]{64}$")

    @field_validator("url")
    @classmethod
    def no_template(cls, v: str) -> str:
        if "${" in v or "{{" in v or "}}" in v:
            raise ValueError("source.url must not contain templating")
        return v


class About(BaseModel):
    license: str
    license_file: str
    license_family: Optional[str] = None


class Recipe(BaseModel):
    about: About
    source: Source


@build_app.command()
def lint(old: str, new: str):
    """
    Validate that all changed recipes have valid metadata using Pydantic schema.
    Checks license fields and source formatting.
    Exits with code 1 if any recipe fails validation.
    """
    recipes_with_changes_per_subdir = find_recipes_with_changes(old=old, new=new)

    failed = False
    for subdir, recipe_with_changes in recipes_with_changes_per_subdir.items():
        for recipe in recipe_with_changes:
            meta_path = Path("recipes") / subdir / recipe / "recipe.yaml"
            if not meta_path.exists():
                print(f"⚠️ Skipping {meta_path}, file not found")
                continue

            try:
                with open(meta_path) as f:
                    meta = yaml.safe_load(f)
            except Exception as e:
                print(f"❌ Failed to parse {meta_path}: {e}")
                failed = True
                continue

            try:
                Recipe.model_validate(meta)  # ✅ v2 style
                print(f"✅ {meta_path} passed validation")
            except Exception as e:
                print(f"❌ {meta_path} failed validation: {e}")
                failed = True

    if failed:
        print("❌ One or more recipes failed validation")
        sys.exit(1)
    else:
        print("✅ All changed recipes passed validation")


if __name__ == "__main__":
    app()
