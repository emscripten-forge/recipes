import contextlib
import subprocess
import os
from dataclasses import dataclass
from enum import Enum
from functools import total_ordering
from pathlib import Path
from typing import Optional
from ruamel.yaml import YAML
import jinja2
import copy
from .next_version import next_version
from .url_exists import url_exists
from .hash_url import hash_url
from ..git_utils import git_branch_ctx, automerge_is_enabled, get_current_branch_name
import json


# `git -c` overrides for the one commit we create per bump. Avoids writing to
# the user's global git config (which fails on read-only $HOME) and is enough
# for the commit to be authored by the bot; other git commands don't care.
_BOT_GIT_ARGS = [
    '-c', 'user.name=emscripten-forge-bot',
    '-c', 'user.email=emscripten-forge-bot@users.noreply.github.com',
]


# @total_ordering + custom __lt__ so we can write `mode >= Mode.edit`.
# The default str comparison would order edit < plan alphabetically, which
# is the wrong pipeline order; we compare by definition position instead.
@total_ordering
class Mode(str, Enum):
    """Ordered pipeline stages. Each mode runs its own stage and every stage below it."""
    check  = "check"    # HEAD candidate URLs until one exists.
    plan   = "plan"     # + download the winning tarball and compute sha256.
    edit   = "edit"     # + create branch, write recipe.yaml, commit locally (no push).
    submit = "submit"   # + push branch, open PR. Default in CI.

    def __lt__(self, other):
        if not isinstance(other, Mode):
            return NotImplemented
        members = list(type(self))
        return members.index(self) < members.index(other)


# recipes the bot should never try to version-bump (odd versioning schemes,
# pinned-by-hand, etc.). Could be replaced by an extra.skip_version_bump
# per-recipe flag later on.
SKIP_RECIPES = {
    'python', 'python_abi', 'libpython',
    'sqlite', 'robotics-toolbox-python',
    'libffi', 'r-base-4.5.3',
}


def discover_recipes(recipe_dir):
    """All recipe subdirs of recipe_dir, minus SKIP_RECIPES."""
    return [
        r for r in Path(recipe_dir).iterdir()
        if r.is_dir() and r.name not in SKIP_RECIPES
    ]


@dataclass
class Candidate:
    """After check_bump: a newer version exists at a known URL, but the tarball isn't hashed yet."""
    recipe_dir: Path
    recipe_file: Path
    name: str
    current_version: str
    new_version: str
    new_url: str
    pr_title: str
    automerge: bool


@dataclass
class BumpAction:
    """After plan_bump: Candidate + the sha256 that would be committed."""
    candidate: Candidate
    new_sha256: str


# custom error derived from Exception
# to say that the recipe cannot be handled
class CannotHandleRecipeException(Exception):

    def __init__(self, recipe_dir, msg):
        self.recipe_dir = recipe_dir
        self.msg = msg
        super().__init__(f"Cannot handle recipe in {recipe_dir}: {msg}")


def find_new_version_url(recipe_file):
    """Read a recipe, iterate candidate versions, HEAD each until one exists.
    Returns (current_version, new_version, new_url) on hit, or (None, None, None). No downloads."""
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

    # some recipes have URL templates that don't vary with version — e.g.
    # commit-pinned experimental recipes use ${{ commit }} in the URL, so every
    # candidate renders to the same tarball. Skipping identical URLs stops the
    # bot from opening a PR that only bumps the version string (see #6698).
    current_url = environment.from_string(url_template).render(**context)

    for new_version in next_version(str(version)):
        new_version_context = copy.deepcopy(context)
        new_version_context['version'] = new_version
        new_url = environment.from_string(url_template).render(**new_version_context)
        if new_url == current_url:
            continue
        if url_exists(new_url):
            return version, new_version, new_url

    # No newer version found — but still return the recipe's version so callers can report it.
    return version, None, None


def update_recipe_version(recipe_file, new_version, new_sha256, is_rattler):

    # read the file
    with open(recipe_file) as file:
        recipe = YAML().load(file)

    # get context
    context = recipe['context']
    context['version'] = new_version

    # reset build number
    if 'build_number' in context:
        context['build_number'] = 0
    else:
        recipe['build']['number'] = 0

    # update sha256 in source
    source = recipe['source']
    if isinstance(source, list):
        # some recipes have paths listed under sources, these are excluded
        if len(source) > 1 and len(source[1]) > 1:
            raise CannotHandleRecipeException(recipe_file, "Multiple sources")
        source = source[0]
    source['sha256'] = new_sha256

    # custom yaml to avoid line wrapping long urls and to preserve the
    # recipe convention of 4-space-indented list dashes (ruamel default is 2).
    yaml = YAML()
    yaml.width = 120
    yaml.indent(mapping=2, sequence=4, offset=2)

    # write the file
    with open(recipe_file, 'w') as file:
        yaml.dump(recipe, file)

def make_pr_title(name, old_version, new_version, target_pr_branch_name):
    if target_pr_branch_name == "main":
        return f"Update {name} from {old_version} to {new_version}"
    else:
        return f"Update {name} from {old_version} to {new_version} [{target_pr_branch_name}]"

def _detect_automerge(recipe_file):
    """Automerge is only enabled if the recipe (or every output) has a tests section."""
    with open(recipe_file) as file:
        recipe = YAML().load(file)
    if 'outputs' in recipe:
        return all('tests' in output for output in recipe['outputs'])
    return 'tests' in recipe


def _branch_name(candidate: Candidate, target_pr_branch_name: str) -> str:
    return f"bump-{candidate.name}_{candidate.current_version}_to_{candidate.new_version}_for_{target_pr_branch_name}"


def check_bump(recipe_dir, target_pr_branch_name):
    """Stage 1: HEAD candidate URLs until one exists. No download, no side effects.
    Returns (recipe_version, Optional[Candidate]). The version is returned even when
    no newer release was found so callers can report the recipe's state either way."""
    recipe_file = recipe_dir / 'recipe.yaml'
    if not recipe_file.exists():
        return None, None

    current_version, new_version, new_url = find_new_version_url(recipe_file)
    if new_version is None:
        return current_version, None

    name = recipe_dir.name
    cand = Candidate(
        recipe_dir=recipe_dir,
        recipe_file=recipe_file,
        name=name,
        current_version=current_version,
        new_version=new_version,
        new_url=new_url,
        pr_title=make_pr_title(name, current_version, new_version, target_pr_branch_name),
        automerge=_detect_automerge(recipe_file),
    )
    return current_version, cand


def plan_bump(candidate: Candidate) -> BumpAction:
    """Stage 2: download the winning tarball and compute sha256."""
    new_sha256 = hash_url(candidate.new_url, hash_type='sha256')
    return BumpAction(candidate=candidate, new_sha256=new_sha256)


def edit_bump(action: BumpAction, target_pr_branch_name):
    """Stage 3: create branch, write recipe.yaml, commit locally. No push, no PR.
    The branch is left in place so a caller can inspect or extend it (e.g. submit_bump)."""
    branch = _branch_name(action.candidate, target_pr_branch_name)
    old_branch = get_current_branch_name()
    subprocess.check_output(['git', 'checkout', '-b', branch])
    try:
        update_recipe_version(action.candidate.recipe_file,
                              new_version=action.candidate.new_version,
                              new_sha256=action.new_sha256, is_rattler=True)
        subprocess.check_output(['git', 'add', str(action.candidate.recipe_dir)])
        subprocess.check_output(['git', *_BOT_GIT_ARGS, 'commit', '-m', action.candidate.pr_title])
    finally:
        subprocess.check_output(['git', 'checkout', old_branch, '--force'])


def submit_bump(action: BumpAction, target_pr_branch_name):
    """Stage 4: push the edit-created branch and open a PR. Assumes edit_bump already ran."""
    branch = _branch_name(action.candidate, target_pr_branch_name)
    subprocess.check_output(['git', 'push', '-u', 'origin', branch, '--force'])
    subprocess.check_call(['gh', 'repo', 'set-default', 'emscripten-forge/recipes'], cwd=os.getcwd())
    subprocess.check_call([
        'gh', 'pr', 'create',
        '-B', target_pr_branch_name,
        '--title', action.candidate.pr_title,
        '--body', 'Beep-boop-beep! Whistle-whistle-woo!',
        '--label', 'Automerge' if action.candidate.automerge else 'Needs Tests',
    ], cwd=os.getcwd())
    # branch is no longer needed locally; delete it so the workspace stays tidy.
    subprocess.check_output(['git', 'branch', '-D', branch])


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
            message += "\nIf you believe you are wrongly pinged, please comment here or open a PR removing you from the maintainers list."

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


def _process_existing_bot_prs(recipes_root, pr_target_branch):
    """Merge/label already-open bot PRs and return the set of recipe names they cover.
    Runs at the start of a real run; skipped in dry-run because it mutates GitHub state."""
    print("Checking opened PRs and merge them if green!")
    command = [
        "gh", "pr", "list",
        "--author", "emscripten-forge-bot",
        "--base", pr_target_branch,
        "--json", "number,title",
        "--limit", "200",  # default is only 30
    ]
    all_prs = json.loads(subprocess.check_output(command).decode('utf-8'))
    prs_id = [pr['number'] for pr in all_prs]
    prs_packages = [pr['title'].split()[1] for pr in all_prs]

    recipe_name_to_recipe_dir = {r.name: r for r in discover_recipes(recipes_root)}

    if pr_target_branch == "main":
        for pr, pr_pkg in zip(prs_id, prs_packages):
            try:
                try_to_merge_pr(pr, recipe_dir=recipe_name_to_recipe_dir.get(pr_pkg), ping=True)
            except Exception as e:
                print(f"Error in {pr}: {e}")

    for pr, pr_pkg in zip(prs_id, prs_packages):
        print(f"PR {pr} is for package {pr_pkg}")

    return set(prs_packages)


def _checkout_target_branch(pr_target_branch):
    current_branch_name = get_current_branch_name()
    if current_branch_name == pr_target_branch:
        print(f"Already on target branch {pr_target_branch}")
        return
    print(f"switching from {current_branch_name} to {pr_target_branch}")
    subprocess.run(['git', 'stash'], check=False)
    print(f"fetch {pr_target_branch}")
    subprocess.check_output(['git', 'fetch', 'origin', pr_target_branch])
    print(f"checkout {pr_target_branch}")
    subprocess.check_output(['git', 'checkout', pr_target_branch])
    print("checkout done")
    assert get_current_branch_name() == pr_target_branch


def bump_recipe_versions(recipe_dir, pr_target_branch, pr_limit=20, mode: Mode = Mode.check):
    print(f"Bumping recipes in {recipe_dir} to {pr_target_branch} [mode={mode.value}]")

    # Side-effect phases only run in submit mode (they mutate GitHub state / current branch).
    recipes_with_open_pr = set()
    if mode == Mode.submit:
        _checkout_target_branch(pr_target_branch)
        recipes_with_open_pr = _process_existing_bot_prs(recipe_dir, pr_target_branch)

    candidates_recipes = [
        r for r in discover_recipes(recipe_dir)
        if r.name not in recipes_with_open_pr
    ]

    # column widths (kept in sync so status lines align):
    #   2sp prefix + 7-char label + 2sp gap + recipe name + optional detail
    total = 0
    for recipe in candidates_recipes:
        try:
            recipe_version, cand = check_bump(recipe, pr_target_branch)
        except Exception as e:
            print(f"  {'error':<7}  {recipe.name}: {e}")
            continue

        if cand is None:
            # printed regardless of mode so the operator can see the full inventory.
            print(f"  {'no bump':<7}  {recipe.name} (recipe @ {recipe_version}, no newer release found)")
            continue

        # from here on the recipe has a bump available.
        print(f"  {'BUMP':<7}  {recipe.name}: recipe @ {cand.current_version} → available {cand.new_version}")
        print(f"             {'url:':<8}{cand.new_url}")
        if mode == Mode.check:
            total += 1
            if pr_limit is not None and total >= pr_limit:
                break
            continue

        try:
            action = plan_bump(cand)
            print(f"             {'sha256:':<8}{action.new_sha256}")

            if mode >= Mode.edit:
                edit_bump(action, pr_target_branch)
            if mode == Mode.submit:
                submit_bump(action, pr_target_branch)
                print(f"             opened PR: {cand.pr_title}")
        except Exception as e:
            print(f"  {'error':<7}  {recipe.name}: {e}")
            continue

        total += 1
        if pr_limit is not None and total >= pr_limit:
            break

    print(f"Total ({mode.value}): {total}")

