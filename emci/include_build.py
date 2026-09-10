# for yaml reading
import yaml
from pathlib import Path
from emci.constants import BUILD_FOR_ARCH_DEFAULT_VALUES

def include_build(recipes_dir, target_platform):
    """
    Determine if a recipe should be included in the CI build.
    For instance, we may want to only build
    for emscripten-wasm32 but not emscripten-wasm64
    """

    recipe_yaml_path = Path(recipes_dir) / "recipe.yaml"

    # read the recipe.yaml file
    with open(recipe_yaml_path, "r") as f:
        recipe_yaml = yaml.safe_load(f)
        extra = recipe_yaml.get("extra", {})
        ci = extra.get("ci", {})
        platforms = ci.get("platforms", {})
        if not isinstance(platforms, dict):
            raise ValueError(f"Expected 'platforms' to be a dict in recipe.yaml at {recipe_yaml_path}")

        # check that each key is valid (ie also a key in BUILD_FOR_ARCH_DEFAULT_VALUES)
        for key in platforms.keys():
            if key not in BUILD_FOR_ARCH_DEFAULT_VALUES:
                raise ValueError(f"Invalid platform: '{key}' in recipe.yaml at {recipe_yaml_path}")

        return platforms.get(target_platform, BUILD_FOR_ARCH_DEFAULT_VALUES[target_platform])


