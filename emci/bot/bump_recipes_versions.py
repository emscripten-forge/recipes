import contextlib
import subprocess
import os
from pathlib import Path
from ruamel.yaml import YAML
from ..git_utils import bot_github_user_ctx, git_branch_ctx, make_pr_for_recipe, automerge_is_enabled,set_bot_user,get_current_branch_name
import json

# custom error derived from Exception
# to say that the recipe cannot be handled
class CannotHandleRecipeException(Exception):

    def __init__(self, recipe_dir, msg):
        self.recipe_dir = recipe_dir
        self.msg = msg
        super().__init__(f"Cannot handle recipe in {recipe_dir}: {msg}")


def get_current_version(recipe_file):
    """Get the current version from the recipe file"""
    with open(recipe_file) as file:
        recipe = YAML().load(file)

    try:
        context = recipe['context']
        version = context['version']
        return version
    except KeyError:
        raise CannotHandleRecipeException(recipe_file, "No version in context")


def check_for_update(recipe_file):
    """Check if there's an update available using rattler-build bump-recipe --check-only"""
    try:
        result = subprocess.run(
            ['rattler-build', 'bump-recipe', '--recipe', str(recipe_file), '--check-only'],
            capture_output=True,
            text=True,
            check=False
        )
        # If exit code is 0, there's an update available
        # If exit code is non-zero, no update or error
        return result.returncode == 0
    except Exception as e:
        print(f"Error checking for updates: {e}")
        return False


def update_recipe_version(recipe_file):
    """Update the recipe version using rattler-build bump-recipe"""
    try:
        result = subprocess.run(
            ['rattler-build', 'bump-recipe', '--recipe', str(recipe_file)],
            capture_output=True,
            text=True,
            check=True
        )
        print(result.stdout)
        if result.stderr:
            print(result.stderr)
        return True
    except subprocess.CalledProcessError as e:
        raise CannotHandleRecipeException(recipe_file, f"Failed to bump recipe: {e}")

def make_pr_title(name, old_version, new_version, target_pr_branch_name):
    if target_pr_branch_name == "main":
        return f"Update {name} from {old_version} to {new_version}"
    else:
        return f"Update {name} from {old_version} to {new_version} [{target_pr_branch_name}]"

def bump_recipe_version(recipe_dir, target_pr_branch_name):

    recipe_fname = 'recipe.yaml'
    if not (recipe_dir / recipe_fname).exists():
        return None, None

    recipe_file = recipe_dir / recipe_fname

    # Get current version before checking for updates
    try:
        current_version = get_current_version(recipe_file)
    except CannotHandleRecipeException:
        return None, None

    # Check if there's an update available
    if not check_for_update(recipe_file):
        print(f"No update available for {recipe_dir.name}")
        return None, None

    # use the last directory in the path as the branch name
    name = recipe_dir.name

    # check if the recipe has test section
    # load recipe
    automerge = True
    with open(recipe_file) as file:
        recipe = YAML().load(file)

        # Multi-outputs recipe
        if hasattr(recipe, "outputs"):
            for i, output in enumerate(recipe["outputs"]):
                if "tests" not in output:
                    automerge = False
                    break
        elif 'tests' not in recipe:
            automerge = False

    # Create branch name - we'll update it after we know the new version
    # Start with a simple name, then rename after bumping
    branch_name = f"bump-{name}_{current_version}_for_{target_pr_branch_name}"

    with git_branch_ctx(branch_name, stash_current=False):

        # update the recipe using rattler-build
        update_recipe_version(recipe_file)

        # Get the new version after the update
        try:
            new_version = get_current_version(recipe_file)
        except CannotHandleRecipeException:
            print(f"Failed to get new version after bumping {name}")
            return None, None

        # Update branch name with actual versions
        new_branch_name = f"bump-{name}_{current_version}_to_{new_version}_for_{target_pr_branch_name}"
        # Rename the current branch
        try:
            subprocess.check_output(['git', 'branch', '-m', new_branch_name], stderr=subprocess.DEVNULL)
            branch_name = new_branch_name
        except subprocess.CalledProcessError:
            # If rename fails, continue with original branch name
            pass

        # commit the changes and make a PR
        pr_title = make_pr_title(name, current_version, new_version, target_pr_branch_name)
        print(f"🛠️ Making PR: {pr_title} with target branch {target_pr_branch_name}")
        print("TODO TESTING make pr for recipe")
        # make_pr_for_recipe(recipe_dir=recipe_dir, pr_title=pr_title, branch_name=branch_name,
        #     target_branch_name=target_pr_branch_name,
        #     automerge=automerge)

    return current_version, new_version


def try_to_merge_pr(pr, recipe_dir=None, ping=False):

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
        if maintainers and ping:
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
            print(f"switching from {current_branch_name} to {pr_target_branch}")
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

        # Merge PRs if possible
        if pr_target_branch in ["main", "emscripten-3x"]:
            for pr,pr_pkg in zip(prs_id, prs_packages):
                # get the recipe dir
                recipe_dir = recipe_name_to_recipe_dir.get(pr_pkg)

                try:
                    print("TODO TESTING try to merge pr")
                    # try_to_merge_pr(pr, recipe_dir=recipe_dir, ping=(pr_target_branch == "main"))
                except Exception as e:
                    print(f"Error in {pr}: {e}")

        # print all ids and the prs_packages
        for pr,pr_pkg in zip(prs_id, prs_packages):
            print(f"PR {pr} is for package {pr_pkg}")

        # only recipes for which there is no opened PR
        all_recipes = [recipe for recipe in all_recipes if recipe.name not in prs_packages]

        skip_recipes = [
            'python', 'python_abi', 'libpython',
            'sqlite', 'libffi'
        ]
        all_recipes = [recipe for recipe in all_recipes if recipe.name not in skip_recipes]


        total_bumped = 0
        for recipe in all_recipes:
            try:
                old_version, new_version = bump_recipe_version(recipe, pr_target_branch)
                if new_version:
                    print(f"Bumped {recipe.name} from {old_version} to {new_version}")
                    total_bumped += 1
            except Exception as e:
                print(f"❌ Error in {recipe.name}:\n{e}\n")

            if pr_limit is not None and total_bumped >= pr_limit:
                break

        # some unstaged
        print("Total bumped: ", total_bumped)

