import contextlib
import subprocess
import os
from pathlib import Path
from ruamel.yaml import YAML
import pprint
import jinja2
import copy
from .next_version import next_version
from .url_exists import url_exists
from .hash_url import hash_url
from ..git_utils import bot_github_user_ctx, current_user_ctx,git_branch_ctx


# custom error derived from Exception
# to say that the recipe cannot be handled
class CannotHandleRecipeException(Exception):
    
    def __init__(self, recipe_dir, msg):
        self.recipe_dir = recipe_dir
        self.msg = msg
        super().__init__(f"Cannot handle recipe in {recipe_dir}: {msg}")





def bump_boa_recipe_version(boa_recipe_file):
    pass





def get_new_version(recipe_file, is_ratler):
    # read the file
    with open(recipe_file) as file:
        recipe = YAML().load(file)

    # get context 
    try:
        context = recipe['context']
    except KeyError:
        raise CannotHandleRecipeException(recipe_file, "No context in recipe")


    # get version from context
    try:
        version = context['version']
    except KeyError:
        raise CannotHandleRecipeException(recipe_file, "No version in context")
            
    # get the url from the source
    try:
        source = recipe['source']
    except KeyError:
        raise CannotHandleRecipeException(recipe_file, "No source in recipe")

    try:
        url_template = source['url']
    except KeyError:
        raise CannotHandleRecipeException(recipe_file, "No url in source")

    # make sure sha256 is in source
    if 'sha256' not in source:
        raise CannotHandleRecipeException(recipe_file, "No sha256 in source")
    
    # check that the url is a template
    if is_ratler:
        if "${{" not in url_template or "}}" not in url_template:
            raise CannotHandleRecipeException(recipe_file, "url is not a template")
    else:
        if "{{" not in url_template or "}}" not in url_template:
            raise CannotHandleRecipeException(recipe_file, "url is not a template")
    
    if is_ratler:
        environment = jinja2.Environment(trim_blocks=True,variable_start_string='${{', variable_end_string='}}')
    else:
        environment = jinja2.Environment(trim_blocks=True,variable_start_string='{{', variable_end_string='}}')

    print("current version: ", version)
    for new_version in next_version(version):
        # render the new url with the new version
        new_version_context = copy.deepcopy(context)
        new_version_context['version'] = new_version
        new_url = environment.from_string(url_template).render(**new_version_context)
        if url_exists(new_url):
            print(f"New version: {version} exists")

            # hash the new url
            new_sha256 = hash_url(new_url, hash_type='sha256')
            print(f"New sha256: {new_sha256}")

            return version, new_version, new_sha256
    
    return None, None,None


def update_recipe_version(recipe_file, new_version, new_sha256, is_ratler):

    # read the file
    with open(recipe_file) as file:
        recipe = YAML().load(file)

    # get context
    context = recipe['context']
    context['version'] = new_version

    # update sha256 in source
    source = recipe['source']
    source['sha256'] = new_sha256

    # write the file
    with open(recipe_file, 'w') as file:
        YAML().dump(recipe, file)

            
def bump_recipe_version(recipe_dir, use_bot=False):

    git_user_ctx = bot_github_user_ctx if use_bot else current_user_ctx

    recipe_locations = [("recipe.yaml", False), ("rattler_recipe.yaml", True)]

    current_version = None
    new_version = None
    new_sha256 = None
    for  recipe_fname, is_rattler in  recipe_locations:
        if (recipe_dir / recipe_fname).exists():
            recipe_file = recipe_dir / recipe_fname
            cv, nv, h = get_new_version(recipe_file, is_ratler=is_rattler)
            if nv is not None:
                new_version = nv
                current_version = cv
                new_sha256 = h
                break

    # no new version found -- nothing to do
    if new_version is None:
        return False, None, None
    
    # use the last directory in the path as the branch name
    name = recipe_dir.name

    branch_name = f"bump-{name}_{current_version}_to_{new_version}"

    print(f"Branch name: {branch_name}")

    with git_user_ctx():
        with git_branch_ctx(branch_name):

            # update the recipe
            for recipe_fname, is_rattler in recipe_locations:
                if (recipe_dir / recipe_fname).exists():
                    recipe_file = recipe_dir / recipe_fname
                    update_recipe_version(recipe_file, new_version=new_version, new_sha256=new_sha256, is_ratler=is_rattler)

    return True , current_version, new_version

           



def bump_recipe_versions(recipe_dir, use_bot=False):


    
    all_recipes = [recipe for recipe in Path(recipe_dir).iterdir() if recipe.is_dir()]

    # // only subset with 'rattler_recipe.yaml' files
    all_recipes = [recipe for recipe in all_recipes if (recipe / 'rattler_recipe.yaml').exists()]
    
    total_bumped = 0
    for recipe in all_recipes:
        try:
            bumped_version, old_version, new_version  = bump_recipe_version(recipe, use_bot=use_bot)
            if bumped_version:
                print(f"Bumped {recipe} from {old_version} to {new_version}")
            total_bumped += int(bumped_version)
        except CannotHandleRecipeException as e:
            print(f"Cannot handle recipe in {e.recipe_dir}: {e.msg}")
        
    

