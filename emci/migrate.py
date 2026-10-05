
import shutil
import tempfile

from .rattler_build import build_with_rattler
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
from hashlib import sha256
import fnmatch
import shutil
from ruamel.yaml import YAML

def iter_outputs(recipe):
    is_multi_output = "outputs" in recipe and len(recipe["outputs"]) > 1
    if is_multi_output:
        for output in recipe["outputs"]:
            yield output
    else:
        yield recipe
    
def iter_requirements(output):
    if "requirements" in output:
        yield output["requirements"]
    
    if "test" in output and "requirements" in output["test"]:
        yield output["test"]["requirements"]

def replace_in_list(lst, old, new):
    return [new if x == old else x for x in lst]


def migrate_recipe(recipe_dir, output_dir):
    recipe_dir = Path(recipe_dir)
    output_dir = Path(output_dir)

    if not output_dir.exists():
        output_dir.mkdir(parents=True)
    dest_dir = output_dir / recipe_dir.name
    if not dest_dir.exists():
        shutil.copytree(recipe_dir, dest_dir)

    # read the file
    recipe_file = dest_dir / "recipe.yaml"
    with open(recipe_file) as file:
        recipe = YAML().load(file)

    for output in iter_outputs(recipe):
        for req in iter_requirements(output):
           if 'host' in req:
                req['host'] = replace_in_list(req['host'], "python", "python-dev")
    
    # write the modified recipe back to the file
    with open(recipe_file, "w") as file:
        YAML().dump(recipe, file)

    



def hash_recipe_content(recipe_content):
    """
    Computes the SHA-256 hash of the given recipe content.

    Args:
        recipe_content (str): Content of the recipe.yaml file.

    Returns:
        str: SHA-256 hash of the recipe content.
    """         
    return sha256(recipe_content.encode("utf-8")).hexdigest()


def get_recipe_hash_build_pkg(pkg_path):
    """
    Extracts the recipe.yaml file from a built package and computes its hash.

    Args:
        pkg_path (str or Path): Path to the built package (.tar.bz2 file).

    Returns:
        str: SHA-256 hash of the recipe.yaml content.
    """
    with TemporaryDirectory() as temp_dir:
        subprocess.run(["tar", "-xzf", str(pkg_path), "-C", temp_dir], check=True)
        # read the recipe.yaml file from the extracted contents
        conda_meta_dir = Path(temp_dir) / "info" / "recipe"/"recipe.yaml"
        if not conda_meta_dir.exists():
            raise FileNotFoundError(f"Recipe file not found in package {pkg_path}")
        # read the recipe.yaml file
        with open(conda_meta_dir, "r") as f:
            return hash_recipe_content(f.read())


def build_with_rattler_wrapper(*args, **kwargs):
    """ 
    Wrapper around the build_with_rattler function that handles subprocess.TimeoutExpired exceptions.

    Args:
        *args: Positional arguments to pass to build_with_rattler.
        **kwargs: Keyword arguments to pass to build_with_rattler.
    """
    try:
        ret = build_with_rattler(*args, **kwargs,  format='tar-bz2', log_style='simple', continue_on_failure=True)
        # parse the JSON output from the build log if needed
        print(f"Build command output:\n{ret.stdout}")
        import json
        import pprint
        try:
            build_log = json.loads(ret.stdout)
        except json.JSONDecodeError as e:
            build_log = None
            print(f"Failed to parse build log as JSON: {e}")
        if build_log is not None:
            pprint.pprint(build_log)

        
        
        return ret
    except subprocess.TimeoutExpired:
        print("Build timed out, continuing with other recipes...")



def post_tentative_build(to_migrate_dir, output_dir, target_platform, pkg_to_recipe_dir):
    # check which recipes were successfully built
    successful_builds = []

    # iterate over all pkgs in outputdir/{target-platform}
    target_output_dir = output_dir / target_platform
    if target_output_dir.exists():
        for pkg_file in target_output_dir.iterdir():


            if pkg_file.is_file() and str(pkg_file).endswith(".tar.bz2"):
                recipe_hash = get_recipe_hash_build_pkg(pkg_file)
                if recipe_hash in pkg_to_recipe_dir:
                    successful_builds.append(pkg_to_recipe_dir[recipe_hash])
    

    print(f"Successfully built recipes: {successful_builds}")


def build_pkg_to_recipe_dir(to_migrate_dir):
    pkg_to_recipe_dir = {}
    for recipe_dir in to_migrate_dir.iterdir():
        if recipe_dir.is_dir() and (recipe_dir / "recipe.yaml").exists():
            # load the recipe.yaml content
            recipe_content = (recipe_dir / "recipe.yaml").read_text()
            # compute hash
            recipe_hash = hash_recipe_content(recipe_content)
            pkg_to_recipe_dir[recipe_hash] = recipe_dir.name
    return pkg_to_recipe_dir


def copy_selected_recipes(to_migrate_dir, wildcards, wildcards_ignore, recipe_transformations, output_dir):
    to_migrate_dir = Path(to_migrate_dir)
    output_dir = Path(output_dir)

    if not output_dir.exists():
        output_dir.mkdir(parents=True)

    for recipe_dir in to_migrate_dir.iterdir():
        if recipe_dir.is_dir() and (recipe_dir / "recipe.yaml").exists():
            # dir_name
            dir_name = recipe_dir.name
            if wildcards is None or any(fnmatch.fnmatch(dir_name, wc) for wc in wildcards):

                if wildcards_ignore is not None and any(fnmatch.fnmatch(dir_name, wc) for wc in wildcards_ignore):
                    continue

                migrate_recipe(recipe_dir, output_dir)



    
def build_tentative(to_migrate_dir, 
                    output_dir, 
                    target_platform='emscripten-wasm32', 
                    timeout=None, 
                    wildcards=None,
                    wildcards_ignore=None):
    """
    entry point for tentative building
    """
    to_migrate_dir = Path(to_migrate_dir)
    output_dir = Path(output_dir)
    if wildcards is None:
        wildcards = ['*']
    if wildcards_ignore is None:
        wildcards_ignore = []


    # sanity checks
    if not to_migrate_dir.exists():
        raise ValueError(f"Source directory {to_migrate_dir} does not exist")
    if not output_dir.exists():
        output_dir.mkdir(parents=True)


    # create temp dir
    with TemporaryDirectory() as temp_dir:
        temp_dir = Path(temp_dir)

        filtered_to_migrate_dir = temp_dir / "filtered_to_migrate"
        filtered_to_migrate_dir.mkdir(parents=True)
        copy_selected_recipes(to_migrate_dir, wildcards, wildcards_ignore, recipe_transformations=[], output_dir=filtered_to_migrate_dir)


        # map recipe.yaml content to directory name 
        # st. we can later map the successful builds 
        # back to their respective recipe dir
        pkg_to_recipe_dir = build_pkg_to_recipe_dir(filtered_to_migrate_dir)

        # build all pkgs
        build_with_rattler_wrapper(recipes_dir=filtered_to_migrate_dir, output_dir=output_dir, 
                        target_platform=target_platform, skip_existing="local", 
                        timeout=timeout)

        # after the build, process the results
        post_tentative_build(to_migrate_dir=to_migrate_dir, 
                            output_dir=output_dir, 
                            target_platform=target_platform, 
                            pkg_to_recipe_dir=pkg_to_recipe_dir)

    