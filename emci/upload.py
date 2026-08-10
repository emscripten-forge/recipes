
# for tempdir
import tempfile
import shutil
from pathlib import Path
import yaml
from .constants import DEFAULT_EMSCRIPTEN_FORGE_CHANNEL

def extract_channel_from_pkg(pkg_file):
    """
    Extract the channel from a conda package file.

    Args:
        pkg_file (str): Path to the conda package file.


    Returns:
        str: The extracted channel name.
    """

    # atm we only take tar.bz2 files
    if not pkg_file.endswith(".tar.bz2"):
        raise ValueError("Only .tar.bz2 files are supported, .conda support needs to be added")

    # extract pkg 
    with tempfile.TemporaryDirectory() as tmp_dir:
        # Extract the package to a temporary directory
        shutil.unpack_archive(pkg_file, tmp_dir)

        # open recipe.yaml from info/recipe/recipe.yaml
        recipe_yaml_path = Path(tmp_dir) / "info" / "recipe" / "recipe.yaml"
        if not recipe_yaml_path.exists():
            raise FileNotFoundError(f"recipe.yaml not found in {pkg_file}")
    
        # Load the recipe.yaml file
        with open(recipe_yaml_path, "r") as f:
            recipe_data = yaml.safe_load(f)

        # Extract the channel from extra section 
        extra_section = recipe_data.get("extra", {})
        channel = extra_section.get("channel", DEFAULT_EMSCRIPTEN_FORGE_CHANNEL)

        return channel
