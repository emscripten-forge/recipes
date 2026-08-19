from .git_utils import find_files_with_changes
import os
import platform


def find_recipes_with_changes(old, new):
    files_with_changes = find_files_with_changes(old=old, new=new)

    recipes_with_changes = {k: set() for k in ["recipes_native", "recipes_wasm"]}
    # print("recipes_with_changes", recipes_with_changes)
    for subdir in ["recipes_native", "recipes_wasm"]:
        if  platform.system() == "Darwin" and subdir == "recipes_wasm":
            # skip recipes_wasm on macOS
            # we only build recipes/recipes on macOS
            continue
            
        for file_with_change in files_with_changes:
            if file_with_change.startswith(f"recipes/{subdir}/"):
                # print(file_with_change)
                file_with_change = file_with_change[len(f"recipes/{subdir}/") :]
                file_with_change = os.path.normpath(file_with_change)
                recipe = file_with_change.split(os.sep)[0]
                if os.path.exists(f"recipes/{subdir}/{recipe}"):
                    recipes_with_changes[subdir].add(recipe)

    for subdir in ["recipes_native", "recipes_wasm"]:
        recipes_with_changes[subdir] = sorted(list(recipes_with_changes[subdir]))
    return recipes_with_changes

