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
        platforms = ci.get("platforms", [])
        if target_platform in platforms:
            # we **include** this platform since its explicitly listed 
            # in the recipe
            return True 
        else:
            return BUILD_FOR_ARCH_DEFAULT_VALUES[target_platform]


