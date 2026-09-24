from .git_utils import find_files_with_changes
import os
import platform
from typing import Optional


RECIPE_SUBDIRS = ("recipes_native", "recipes_wasm")


def find_recipes_with_changes(old, new, subdir: Optional[str] = None):
    if subdir is not None and subdir not in RECIPE_SUBDIRS:
        raise ValueError(
            f"Invalid subdir={subdir!r}; expected one of {RECIPE_SUBDIRS}"
        )

    files_with_changes = find_files_with_changes(old=old, new=new)

    subdirs = (subdir,) if subdir is not None else RECIPE_SUBDIRS
    recipes_with_changes = {k: set() for k in RECIPE_SUBDIRS}
    for current_subdir in subdirs:
        if platform.system() == "Darwin" and current_subdir == "recipes_wasm":
            # skip recipes_wasm on macOS
            # we only build recipes/recipes_native on macOS
            # otherwise we would build recipes_wasm on mac and linux and 
            # would try to upload the same recipe twice. Furthermore 
            # its easier to build recipes_wasm on linux than on macOS
            # since emscripten-wasm32/emscripten-wasm64 is closer
            # to linux than to macOS. 
            continue

        for file_with_change in files_with_changes:
            if file_with_change.startswith(f"recipes/{current_subdir}/"):
                file_with_change = file_with_change[len(f"recipes/{current_subdir}/") :]
                file_with_change = os.path.normpath(file_with_change)
                recipe = file_with_change.split(os.sep)[0]
                if os.path.exists(f"recipes/{current_subdir}/{recipe}"):
                    recipes_with_changes[current_subdir].add(recipe)

    for current_subdir in RECIPE_SUBDIRS:
        recipes_with_changes[current_subdir] = sorted(
            list(recipes_with_changes[current_subdir])
        )
    return recipes_with_changes

