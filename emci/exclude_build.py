# for yaml reading
import yaml
from pathlib import Path

def exclude_build(recipes_dir, target_platform):
    """
    Determine if a recipe should be skipped in the ci.
    For instance we may want to only build
    for emscripten-wasm32 but not emscripten-wasm64
    """

    recipe_yaml_path = Path(recipes_dir) / "recipe.yaml"

    # read the recipe.yaml file
    with open(recipe_yaml_path, "r") as f:
        recipe_yaml = yaml.safe_load(f)
        extra = recipe_yaml.get("extra", {})
        ci = extra.get("ci", {})
        exclude_platforms = ci.get("exclude_platforms", [])
        if target_platform in exclude_platforms:
            return True

    return False