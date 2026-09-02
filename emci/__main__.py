from .rattler_build import build_with_rattler
from .constants import RECIPES_EMSCRIPTEN_DIR
from .find_recipes_with_changes import find_recipes_with_changes
from .playwright import changed_recipes_need_playwright
from .lint import lint_recipe_file, lint_recipes
from .upload import extract_channel_from_pkg

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


upload_app = typer.Typer()
app.add_typer(upload_app, name="upload")

@upload_app.command()
def extract_channel(pkg_file):
    print(extract_channel_from_pkg(pkg_file))

@build_app.command()
def changed(
    root_dir,
    old,
    new,
    target_platform: Optional[str] = typer.Option(None),
    dryrun: Optional[bool] = typer.Option(False),
    skip_tests: Optional[bool] = typer.Option(False),
    skip_existing: Optional[bool] = typer.Option(True)
):
    if target_platform == "None":
        target_platform = None

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


            n_recipes = 0
            for recipe_with_change in recipe_with_changes:

                recipe_dir = os.path.join(recipes_dir, subdir, recipe_with_change)

                # diff can shown deleted recipe as changed
                if os.path.isdir(recipe_dir):
                    if exclude_build(recipe_dir, target_platform):
                        print(f"Excluding build for recipe {recipe_with_change} for target_platform={target_platform}")
                    else:
                        print(f"Copying recipe {recipe_with_change} to temp dir for target_platform={target_platform}")
                        tmp_recipe_dir = os.path.join(
                            tmp_recipes_root_str, recipe_with_change
                        )
                        # os.mkdir(tmp_recipe_dir)
                        shutil.copytree(recipe_dir, tmp_recipe_dir)
                        n_recipes += 1
            if n_recipes == 0:
                print(f"No recipes to build for target_platform={target_platform} in subdir={subdir}")
                continue
            print([x[0] for x in os.walk(tmp_recipes_root_str)])

            # delete all potential "recipe_legacy.yaml" files
            for root, dirs, files in os.walk(tmp_recipes_root_str):
                for file in files:
                    if file == "recipe_legacy.yaml":
                        os.remove(os.path.join(root, file))
            tp = str(target_platform) 
            if subdir == "recipes_native":
                tp = None
            print(f"Building recipes in {tmp_recipes_root_str} for target_platform={target_platform} subdir={subdir}")
            build_with_rattler(recipe=None, recipes_dir=tmp_recipes_root_str, target_platform=tp, skip_existing="local")


bot_app = typer.Typer()
app.add_typer(bot_app, name="bot")


@bot_app.command()
def bump_recipes_versions(target_branch_name: str):
    from .bot.bump_recipes_versions import bump_recipe_versions

    bump_recipe_versions(RECIPES_EMSCRIPTEN_DIR, target_branch_name)


@bot_app.command()
def update_matplotlib_fontcache(target_branch_name: str):
    from .bot.update_matplotlib_fontcache import update_matplotlib_fontcache

    update_matplotlib_fontcache(RECIPES_EMSCRIPTEN_DIR, target_branch_name)


@build_app.command("needs-playwright")
def needs_playwright(old: str, new: str):
    """Print true/false depending on whether changed recipes need playwright."""
    if changed_recipes_need_playwright(old, new):
        print("true")
    else:
        print("false")


@app.command()
def lint(
    old: Optional[str] = typer.Argument(None, help="Git ref for the old commit"),
    new: Optional[str] = typer.Argument(None, help="Git ref for the new commit"),
    file: Optional[Path] = typer.Option(
        None,
        "--file",
        help="Path to a recipe.yaml or a recipe directory containing recipe.yaml",
    ),
):
    """
    Validate recipe metadata using Pydantic schema.

    Lint changed recipes between two git refs, or a single recipe with --file.
    Exits with code 1 if any recipe fails validation.
    """
    if file is not None:
        if old is not None or new is not None:
            print("❌ Cannot use --file together with old/new git refs", file=sys.stderr)
            raise typer.Exit(1)
        if not lint_recipe_file(file):
            raise typer.Exit(1)
        return

    if old is None or new is None:
        print(
            "❌ Provide both old and new git refs, or use --file to lint a single recipe",
            file=sys.stderr,
        )
        raise typer.Exit(1)

    lint_recipes(old, new)


@app.command()
def sync(
    migration_ref: str = typer.Argument(
        ...,
        help="Migration branch as remote/branch or branch (default remote: origin)",
    ),
    old: str = typer.Argument(..., help="Git ref for the old commit"),
    new: str = typer.Argument(..., help="Git ref for the new commit"),
    dry_run: bool = typer.Option(
        False,
        "--dry-run",
        help="Apply file changes on a new branch and print the PR title/body without committing or opening a PR",
    ),
):
    """Sync recipe changes from main onto a migration branch and open a PR."""
    from .sync_migration_branch import sync_migration_branch

    sync_migration_branch(migration_ref, old, new, dry_run=dry_run)


if __name__ == "__main__":
    app()
