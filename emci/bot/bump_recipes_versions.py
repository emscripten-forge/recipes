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
from ..git_utils import bot_github_user_ctx, git_branch_ctx, make_pr_for_recipe, automerge_is_enabled,set_bot_user,get_current_branch_name
import sys
import json

# custom error derived from Exception
# to say that the recipe cannot be handled
class CannotHandleRecipeException(Exception):

    def __init__(self, recipe_dir, msg):
        self.recipe_dir = recipe_dir
        self.msg = msg
        super().__init__(f"Cannot handle recipe in {recipe_dir}: {msg}")


def get_new_version(recipe_file):
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

    if isinstance(source, list):
        # some recipes have paths listed under sources, these are excluded
        if len(source) > 1 and len(source[1]) > 1:
            raise CannotHandleRecipeException(recipe_file, "Multiple sources")
        source = source[0]

    # make sure sha256 is in source
    if 'sha256' not in source:
        raise CannotHandleRecipeException(recipe_file, "No sha256 in source")

    try:
        url_template = source['url']
    except KeyError:
        raise CannotHandleRecipeException(recipe_file, "No url in source")

    # only check the first url, the others are backups
    if isinstance(url_template, list):
        url_template = url_template[0]

    if "${{" not in url_template or "}}" not in url_template:
            raise CannotHandleRecipeException(recipe_file, "url is not a template")

    environment = jinja2.Environment(trim_blocks=True,variable_start_string='${{', variable_end_string='}}')

    # get name from dir
    name = recipe_file.parent.name

    print(f"{name} current version: ", version)
    for new_version in next_version(str(version)):
        # render the new url with the new version
        new_version_context = copy.deepcopy(context)
        new_version_context['version'] = new_version
        new_url = environment.from_string(url_template).render(**new_version_context)
        if url_exists(new_url):
            print(f"- found new version: {new_version}")

            # hash the new url
            new_sha256 = hash_url(new_url, hash_type='sha256')
            print(f"- new sha256: {new_sha256}")

            return version, new_version, new_sha256

    return None, None,None


def update_recipe_version(recipe_file, new_version, new_sha256, is_rattler):

    # read the file
    with open(recipe_file) as file:
        recipe = YAML().load(file)

    # get context
    context = recipe['context']
    context['version'] = new_version

    # reset build number
    recipe['build']['number'] = 0

    # update sha256 in source
    source = recipe['source']
    if isinstance(source, list):
        # some recipes have paths listed under sources, these are excluded
        if len(source) > 1 and len(source[1]) > 1:
            raise CannotHandleRecipeException(recipe_file, "Multiple sources")
        source = source[0]
    source['sha256'] = new_sha256

    # custom yaml to avoid line wrapping long urls
    yaml = YAML()
    yaml.width = 120

    # write the file
    with open(recipe_file, 'w') as file:
        yaml.dump(recipe, file)

def make_pr_title(name, old_version, new_version, target_pr_branch_name):
    if target_pr_branch_name == "main":
        return f"Update {name} from {old_version} to {new_version}"
    else:
        return f"Update {name} from {old_version} to {new_version} [{target_pr_branch_name}]"

def bump_recipe_version(recipe_dir, target_pr_branch_name):

    recipe_locations = [ ("recipe.yaml", True)]

    current_version = None
    new_version = None
    new_sha256 = None


    recipe_fname = 'recipe.yaml'
    if (recipe_dir / recipe_fname).exists():
        recipe_file = recipe_dir / recipe_fname
        cv, nv, h = get_new_version(recipe_file)
        if nv is not None:
            new_version = nv
            current_version = cv
            new_sha256 = h
    else:
        return False, None, None


    # no new version found -- nothing to do
    if new_version is None:
        return False, None, None

    # use the last directory in the path as the branch name
    name = recipe_dir.name

    # check if the recipe has test section
    # load recipe
    automerge = True
    with open(recipe_file) as file:
        recipe = YAML().load(file)

        # Multi-outputs recipe
        if hasattr(recipe, "outputs"):
            for i, output in enumerate(outputs):
                 if "tests" not in output:
                     automerge = False
                     break
        elif 'tests' not in recipe:
            automerge = False


    branch_name = f"bump-{name}_{current_version}_to_{new_version}_for_{target_pr_branch_name}"


    with git_branch_ctx(branch_name, stash_current=False):

        # update the recipe
        for recipe_fname, is_rattler in recipe_locations:
            if (recipe_dir / recipe_fname).exists():
                recipe_file = recipe_dir / recipe_fname
                update_recipe_version(recipe_file, new_version=new_version, new_sha256=new_sha256, is_rattler=is_rattler)

        # commit the changes and make a PR
        pr_title = make_pr_title(name, current_version, new_version, target_pr_branch_name)
        print(f"Making PR for {name} with title: {pr_title} with target branch {target_pr_branch_name}")
        make_pr_for_recipe(recipe_dir=recipe_dir, pr_title=pr_title, branch_name=branch_name,
            target_branch_name=target_pr_branch_name,
            automerge=automerge)

    return True , current_version, new_version


def try_to_merge_pr(pr, recipe_dir=None):

    passed = subprocess.run(
        ['gh', 'pr', 'checks', str(pr)],
        stdout=subprocess.DEVNULL,
    )

    # Debug: print labels
    labels = json.loads(subprocess.check_output(['gh', 'pr', 'view', str(pr), '--json', 'labels']).decode('utf-8'))
    print(f'Labels for PR {pr}: {labels}')

    if passed.returncode == 0 and automerge_is_enabled(pr):
        # PR passed and automerge is enabled, let's merge it
        subprocess.check_output(['gh', 'pr', 'comment', str(pr), '--body', 'CI passed! I\'m merging'])
        subprocess.check_output(['gh', 'pr', 'merge', str(pr), '--squash', '--delete-branch', '--admin'])
    else:
        # Pin recipe maintainer? Or add assignee?
        subprocess.check_output(['gh', 'pr', 'edit', str(pr), '--add-label', 'Needs Human Review'])

        maintainers = []
        if recipe_dir is not None:
            with open(Path(recipe_dir)/"recipe.yaml") as file:
                recipe = YAML().load(file) 
                if 'extra' in recipe:
                    if 'recipe-maintainers' in recipe['extra']:
                        maintainers = recipe['extra']['recipe-maintainers']

        message = """Either the CI is failing, or the recipe is not tested. I need help from a human."""
        if maintainers:
            message += "\nPing the maintainers: "
            for maintainer in maintainers:
                message += f"@{maintainer} "
            message += "\nIf you believe you are wrongly pinned, please comment here or open a PR removing you from the maintainers list."

        try:
            # Running edit-last in case there was already a comment, we don't want to spam with comments
            subprocess.check_output(['gh', 'pr', 'comment', str(pr), '--body', message, '--edit-last'])
        except:
            subprocess.check_output(['gh', 'pr', 'comment', str(pr), '--body', message])


ON_GITHUB_ACTIONS = os.environ.get('GITHUB_ACTIONS') == 'true'

@contextlib.contextmanager
def user_ctx(user, email, bypass=False):
    if ON_GITHUB_ACTIONS and not bypass:
        yield
    else:
        subprocess.check_output(['git', 'config', 'user.name', user])
        subprocess.check_output(['git', 'config', 'user.email', email])
        yield
        subprocess.check_output(['git', 'config', '--unset', 'user.name'])
        subprocess.check_output(['git', 'config', '--unset', 'user.email'])


def bump_recipe_versions(recipe_dir, pr_target_branch, use_bot=True, pr_limit=20):
    print(f"Bumping recipes in {recipe_dir} to {pr_target_branch}")
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



    # get all opened PRs
    with user_ctx():

        current_branch_name = get_current_branch_name()
        if current_branch_name == pr_target_branch:
            print(f"Already on target branch {pr_target_branch}")
        else:
            print(f"swichting from {current_branch_name} to {pr_target_branch}")
            # switch to the target branch
            subprocess.run(['git', 'stash'], check=False)
            print(f"fetch {pr_target_branch}")
            subprocess.check_output(['git', 'fetch', 'origin', pr_target_branch])
            print(f"checkout {pr_target_branch}")
            subprocess.check_output(['git', 'checkout', pr_target_branch])
            print("checkout done")

        assert get_current_branch_name() == pr_target_branch
        current_branch_name = pr_target_branch

        # Check for opened PRs and merge them if the CI passed
        print("Checking opened PRs and merge them if green!")

        command = [
            "gh", "pr", "list",
            "--author", "emscripten-forge-bot",
            "--base", pr_target_branch,
            "--json", "number,title",
            "--limit", "200" # default is only 30
        ]
        # run command and get the output as json
        all_prs = json.loads(subprocess.check_output(command).decode('utf-8'))

        all_recipes = [recipe for recipe in Path(recipe_dir).iterdir() if recipe.is_dir()]
        # map from folder names to recipe-dir
        recipe_name_to_recipe_dir = {recipe.name: recipe for recipe in all_recipes}


        prs_id = [pr['number'] for pr in all_prs]
        prs_packages = [pr['title'].split()[1] for pr in all_prs]

        # Merge PRs if possible (only for main atm)
        if pr_target_branch == "main":
            for pr,pr_pkg in zip(prs_id, prs_packages):
                # get the recipe dir
                recipe_dir = recipe_name_to_recipe_dir.get(pr_pkg)

                try:
                    try_to_merge_pr(pr, recipe_dir=recipe_dir)
                except Exception as e:
                    print(f"Error in {pr}: {e}")

        # print all ids and the prs_packages
        for pr,pr_pkg in zip(prs_id, prs_packages):
            print(f"PR {pr} is for package {pr_pkg}")

        # only recipes for which there is no opened PR
        all_recipes = [recipe for recipe in all_recipes if recipe.name not in prs_packages]

        skip_recipes = [
            'python', 'python_abi', 'libpython',
            'sqlite', 'robotics-toolbox-python', 
            'xvega', 'xvega-bindings', 'libffi'
        ]
        all_recipes = [recipe for recipe in all_recipes if recipe.name not in skip_recipes]


        total_bumped = 0
        for recipe in all_recipes:
            try:
                bumped_version, old_version, new_version = bump_recipe_version(recipe, pr_target_branch)
                if bumped_version:
                    print(f"Bumped {recipe} from {old_version} to {new_version}")
                total_bumped += int(bumped_version)
            except Exception as e:
                print(f"Error in {recipe}: {e}")

            if pr_limit is not None and total_bumped >= pr_limit:
                break

        # some unstaged
        print("Total bumped: ", total_bumped)

