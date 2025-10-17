import json
import requests
from pathlib import Path
import yaml
from ruamel.yaml import YAML
import os
import contextlib
import subprocess
from ..git_utils import bot_github_user_ctx, git_branch_ctx, make_pr_for_recipe, automerge_is_enabled,set_bot_user,get_current_branch_name


# branch to repodata mapping
branch_to_repodata_mapping = {
    "main": "https://repo.prefix.dev/emscripten-forge-dev/emscripten-wasm32/repodata.json",
    "emscripten-4x": "https://repo.prefix.dev/emscripten-forge-4x/emscripten-wasm32/repodata.json"
}

ON_GITHUB_ACTIONS = os.environ.get('GITHUB_ACTIONS') == 'true'

def bump_build_number(recipe_path):

    # read the file
    with open(recipe_path) as file:
        recipe = YAML().load(file)


    build_number = recipe['build']['number']


    # reset build number
    recipe['build']['number'] = build_number + 1

  
    # custom yaml to avoid line wrapping long urls
    yaml = YAML()
    yaml.width = 120

    # write the file
    with open(recipe_path, 'w') as file:
        yaml.dump(recipe, file)


def get_name(recipe_dir):
    # read recipe.yaml
    recipe_path = recipe_dir / "recipe.yaml"
    with open(recipe_path) as file:
        recipe = YAML().load(file)
    try:
        return  recipe["context"]["name"]
    except KeyError:
        raise ValueError(f"Recipe {recipe_dir} does not have a name in context")

def build_missing_recipes(recipes_dir, pr_target_branch, use_bot=True, pr_limit=20):
    print(f"Create PRs for missing recipes in {recipes_dir} for target branch {pr_target_branch}")

    # empty context manager
    @contextlib.contextmanager
    def empty_context_manager():
        yield

    if ON_GITHUB_ACTIONS:
        # We are on GitHub Actions, we **cannot** **restore** the user account
        # therefore we just set the bot user and use an empty context manager
        set_bot_user()
        user_ctx = empty_context_manager
    else:
        if use_bot:
            user_ctx = bot_github_user_ctx
        else:
            user_ctx = empty_context_manager


    with user_ctx():


        current_branch_name = get_current_branch_name()
        if current_branch_name == pr_target_branch:
            print(f"Already on target branch {pr_target_branch}")
        else:
            print(f"switching from {current_branch_name} to {pr_target_branch}")
            # switch to the target branch
            subprocess.run(['git', 'stash'], check=False)
            print(f"fetch {pr_target_branch}")
            subprocess.check_output(['git', 'fetch', 'origin', pr_target_branch])
            print(f"checkout {pr_target_branch}")
            subprocess.check_output(['git', 'checkout', pr_target_branch])
            print("checkout done")



        # download repodata
        repodata_url = branch_to_repodata_mapping.get(pr_target_branch)
        if not repodata_url:
            raise ValueError(f"Unknown branch: {pr_target_branch}")

        response = requests.get(repodata_url)
        response.raise_for_status()
        repodata = response.json()

        exisiting_pkgs = set()
        for package in repodata["packages"].values():
            # print package names
            exisiting_pkgs.add(package["name"])

        # get all existing PRs from the bot to avoid duplicates
        command = ["gh","pr","list","--author","emscripten-forge-bot","--base",pr_target_branch,"--json","number,title"]
        # run command and get the output as json
        all_prs = json.loads(subprocess.check_output(command).decode('utf-8'))



        prs_id = [pr['number'] for pr in all_prs]
        prs_packages = [pr['title'].split()[1] for pr in all_prs]


        num_prs_made = 0
        # iterate over all recipes and check if they are in repodata
        for recipe_dir in Path(recipes_dir).iterdir():
            if not recipe_dir.is_dir():
                continue

            try:

                recipe_name = get_name(recipe_dir)
                if recipe_name in prs_packages:
                    print(f"PR for {recipe_name} already exists, skipping")
                    continue


                print(f"Checking recipe: {recipe_name}")
                if recipe_name in exisiting_pkgs:
                    print(f"Recipe {recipe_name} already in repodata, skipping")
                    continue

                # create PR to build the recipe
                branch_name = f"initial-build-{recipe_name}_for_{pr_target_branch}"

                recipe_path = recipe_dir / "recipe.yaml"


                automerge = False
                with open(recipe_path) as file:
                    recipe = YAML().load(file)
                    if 'tests' in recipe:
                        automerge = True



                with git_branch_ctx(branch_name, stash_current=False):
                    bump_build_number(recipe_path)
                    

                    # commit the changes and make a PR
                    pr_title =f"Build {recipe_name} for {pr_target_branch}"
                    print(f"Build {recipe_name} with title: {pr_title} with target branch {pr_target_branch}")
                    make_pr_for_recipe(recipe_dir=recipe_dir, pr_title=pr_title, branch_name=branch_name,
                        target_branch_name=pr_target_branch,
                        automerge=automerge)

                    num_prs_made += 1
                    if num_prs_made >= pr_limit:
                        print(f"Reached PR limit of {pr_limit}, stopping")
                        return
            except Exception as e:
                print(f"Error processing recipe in {recipe_dir}: {e}")
                continue
