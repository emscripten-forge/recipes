import contextlib
import difflib
import shlex
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
# the user's global git config and is enough for the commit to be authored by
# the bot; other git commands don't care.
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


# Side-effect operations that edit + submit produce. The runner (execute) or
# the printer (print_ops) decides whether they actually happen. Sharing the
# same op list between them means dry-run can never silently diverge from
# real-run — both consume the exact same commands.
@dataclass
class SubprocessCmd:
    argv: list


@dataclass
class FileWrite:
    path: Path
    content: str


def execute(ops):
    for op in ops:
        if isinstance(op, SubprocessCmd):
            subprocess.check_output(op.argv)
        elif isinstance(op, FileWrite):
            op.path.write_text(op.content)


def print_ops(ops):
    for op in ops:
        if isinstance(op, SubprocessCmd):
            print(f"     [dry] would run    {shlex.join(op.argv)}")
        elif isinstance(op, FileWrite):
            old = op.path.read_text() if op.path.exists() else ""
            print(f"     [dry] would write  {op.path}")
            diff = difflib.unified_diff(
                old.splitlines(keepends=True),
                op.content.splitlines(keepends=True),
                fromfile=str(op.path),
                tofile=str(op.path),
                n=1,
            )
            for line in diff:
                print(f"     [dry]   {line.rstrip()}")


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
class BumpAction(Candidate):
    """After plan_bump: a Candidate with the sha256 and the pre-built op lists for
    the edit and submit stages. Inherits from Candidate so `action.name` still works.
    edit/submit_bump just consume these ops (via execute or print_ops)."""
    new_sha256: str
    edit_ops: list         # main ops for the edit stage.
    edit_cleanup: list     # always-run cleanup (restore original branch).
    submit_ops: list       # ops for the submit stage.


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


def compute_new_recipe_yaml(recipe_file, new_version, new_sha256):
    """Read the recipe, apply the version+sha256 bump in memory, return the new
    file contents as a string. Pure: no writes."""
    import io

    with open(recipe_file) as file:
        recipe = YAML().load(file)

    context = recipe['context']
    context['version'] = new_version

    # reset build number
    if 'build_number' in context:
        context['build_number'] = 0
    else:
        recipe['build']['number'] = 0

    source = recipe['source']
    if isinstance(source, list):
        # some recipes have paths listed under sources, these are excluded
        if len(source) > 1 and len(source[1]) > 1:
            raise CannotHandleRecipeException(recipe_file, "Multiple sources")
        source = source[0]
    source['sha256'] = new_sha256

    # custom yaml to avoid line wrapping long urls; normalise block sequences
    # to 2-space dashes (ruamel default; standardises across recipes).
    yaml = YAML()
    yaml.width = 120
    yaml.indent(mapping=2, sequence=2, offset=0)

    stream = io.StringIO()
    yaml.dump(recipe, stream)
    return stream.getvalue()

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


def plan_bump(candidate: Candidate, target_pr_branch_name: str) -> BumpAction:
    """Stage 2: download the winning tarball, compute sha256, and build the full op
    plan for the edit + submit stages. Ops are pure data — the runner decides
    whether they execute or just get printed. No side effects beyond the network
    HEAD/GET for the tarball hash."""
    new_sha256 = hash_url(candidate.new_url, hash_type='sha256')
    branch = _branch_name(candidate, target_pr_branch_name)
    new_content = compute_new_recipe_yaml(candidate.recipe_file, candidate.new_version, new_sha256)
    old_branch = get_current_branch_name()

    edit_ops = [
        SubprocessCmd(['git', 'checkout', '-b', branch]),
        FileWrite(candidate.recipe_file, new_content),
        SubprocessCmd(['git', 'add', str(candidate.recipe_dir)]),
        SubprocessCmd(['git', *_BOT_GIT_ARGS, 'commit', '-m', candidate.pr_title]),
    ]
    edit_cleanup = [SubprocessCmd(['git', 'checkout', old_branch, '--force'])]
    submit_ops = [
        SubprocessCmd(['git', 'push', '-u', 'origin', branch, '--force']),
        SubprocessCmd(['gh', 'repo', 'set-default', 'emscripten-forge/recipes']),
        SubprocessCmd([
            'gh', 'pr', 'create',
            '-B', target_pr_branch_name,
            '--title', candidate.pr_title,
            '--body', 'Beep-boop-beep! Whistle-whistle-woo!',
            '--label', 'Automerge' if candidate.automerge else 'Needs Tests',
        ]),
        # branch is no longer needed locally; delete it so the workspace stays tidy.
        SubprocessCmd(['git', 'branch', '-D', branch]),
    ]

    return BumpAction(
        **candidate.__dict__,
        new_sha256=new_sha256,
        edit_ops=edit_ops,
        edit_cleanup=edit_cleanup,
        submit_ops=submit_ops,
    )


def edit_bump(action: BumpAction, dry_run=False):
    """Stage 3: run the pre-built edit ops (or print them). Cleanup always runs
    to restore the original branch, even if the main ops fail."""
    if dry_run:
        print_ops(action.edit_ops + action.edit_cleanup)
        return
    try:
        execute(action.edit_ops)
    finally:
        execute(action.edit_cleanup)


def submit_bump(action: BumpAction, dry_run=False):
    """Stage 4: run the pre-built submit ops (or print them)."""
    if dry_run:
        print_ops(action.submit_ops)
        return
    execute(action.submit_ops)


def try_to_merge_pr(pr, recipe_dir=None, ping=False):
    """Reads run inline (needed to decide). Returns the mutation ops the caller
    should execute or print — never mutates GitHub itself."""
    passed = subprocess.run(
        ['gh', 'pr', 'checks', str(pr)],
        stdout=subprocess.DEVNULL,
    )

    # Debug: print labels
    labels = json.loads(subprocess.check_output(['gh', 'pr', 'view', str(pr), '--json', 'labels']).decode('utf-8'))
    print(f'Labels for PR {pr}: {labels}')

    if passed.returncode == 0 and automerge_is_enabled(pr):
        # PR passed and automerge is enabled, let's merge it
        return [
            SubprocessCmd(['gh', 'pr', 'comment', str(pr), '--body', "CI passed! I'm merging"]),
            SubprocessCmd(['gh', 'pr', 'merge', str(pr), '--squash', '--delete-branch', '--admin']),
        ]

    maintainers = []
    if recipe_dir is not None:
        with open(Path(recipe_dir)/"recipe.yaml") as file:
            recipe = YAML().load(file)
            if 'extra' in recipe:
                if 'recipe-maintainers' in recipe['extra']:
                    maintainers = recipe['extra']['recipe-maintainers']

    message = "Either the CI is failing, or the recipe is not tested. I need help from a human."
    if maintainers and ping:
        message += "\nPing the maintainers: "
        for maintainer in maintainers:
            message += f"@{maintainer} "
        message += "\nIf you believe you are wrongly pinged, please comment here or open a PR removing you from the maintainers list."

    # --edit-last updates the existing bot comment when one exists, otherwise
    # creates one on recent gh versions. The prior code fell back to a fresh
    # comment on failure; we accept that lost fallback in exchange for a single
    # op we can print in dry-run.
    return [
        SubprocessCmd(['gh', 'pr', 'edit', str(pr), '--add-label', 'Needs Human Review']),
        SubprocessCmd(['gh', 'pr', 'comment', str(pr), '--body', message, '--edit-last']),
    ]


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


def _fetch_open_bot_prs(pr_target_branch):
    """Pure read: list open bot-authored PRs against the target branch.
    Returns parallel lists (ids, package_names)."""
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
    return prs_id, prs_packages


def _process_existing_bot_prs(recipes_root, pr_target_branch, dry_run=False):
    """Merge/label already-open bot PRs and return the set of recipe names they cover.
    Reads run for real (needed to decide what to do); mutation ops are executed
    or printed based on dry_run."""
    print("Checking opened PRs and merge them if green!")
    prs_id, prs_packages = _fetch_open_bot_prs(pr_target_branch)

    recipe_name_to_recipe_dir = {r.name: r for r in discover_recipes(recipes_root)}
    runner = print_ops if dry_run else execute

    for pr, pr_pkg in zip(prs_id, prs_packages):
        print(f"PR #{pr}  ({pr_pkg})")
        if pr_target_branch == "main":
            try:
                ops = try_to_merge_pr(pr, recipe_dir=recipe_name_to_recipe_dir.get(pr_pkg), ping=True)
                runner(ops)
            except Exception as e:
                print(f"  error: {e}")

    return set(prs_packages)


def _checkout_target_branch(pr_target_branch, dry_run=False):
    """Return-early read to check current branch; the actual stash / fetch /
    checkout are ops that get executed or printed based on dry_run."""
    current_branch_name = get_current_branch_name()
    if current_branch_name == pr_target_branch:
        print(f"Already on target branch {pr_target_branch}")
        return
    print(f"switching from {current_branch_name} to {pr_target_branch}")
    ops = [
        SubprocessCmd(['git', 'stash']),
        SubprocessCmd(['git', 'fetch', 'origin', pr_target_branch]),
        SubprocessCmd(['git', 'checkout', pr_target_branch]),
    ]
    if dry_run:
        print_ops(ops)
        return
    execute(ops)
    print("checkout done")
    assert get_current_branch_name() == pr_target_branch


def merge_open_bot_prs(recipe_dir, pr_target_branch, dry_run=False):
    """Public entry for the `merge-open-prs` subcommand: run only the
    merge/label pass over already-open bot PRs. No new bumps produced."""
    if dry_run:
        print("=" * 72)
        print("  DRY RUN — no gh mutations")
        print("=" * 72)
    print(f"Merging open bot PRs on {pr_target_branch}{' [dry-run]' if dry_run else ''}")
    _process_existing_bot_prs(recipe_dir, pr_target_branch, dry_run=dry_run)
    if dry_run:
        print("=" * 72)
        print("  DRY RUN complete — nothing was actually executed")
        print("=" * 72)


def bump_recipe_versions(recipe_dir, pr_target_branch, pr_limit=20, mode: Mode = Mode.check, only_recipes=None, dry_run=False):
    if dry_run:
        print("=" * 72)
        print("  DRY RUN — no writes, no git mutations, no gh mutations, no PRs")
        print("=" * 72)
    print(f"Bumping recipes in {recipe_dir} to {pr_target_branch} [mode={mode.value}{', dry-run' if dry_run else ''}]")

    # In submit mode we still need to checkout the target branch so new bump
    # branches spawn from the right base. Merging/labeling existing bot PRs is
    # a separate concern now — see the `merge-open-prs` subcommand.
    #
    # We do a read-only fetch of open bot PRs so we can skip recipes that
    # already have one, unless the caller scoped to specific recipes.
    recipes_with_open_pr = set()
    if mode == Mode.submit:
        _checkout_target_branch(pr_target_branch, dry_run=dry_run)
    if mode == Mode.submit and not only_recipes:
        _, packages = _fetch_open_bot_prs(pr_target_branch)
        recipes_with_open_pr = set(packages)

    candidates_recipes = [
        r for r in discover_recipes(recipe_dir)
        if r.name not in recipes_with_open_pr
    ]

    if only_recipes:
        only = set(only_recipes)
        found = {r.name for r in candidates_recipes if r.name in only}
        missing = only - found
        if missing:
            print(f"warning: --recipe not found in {recipe_dir}: {sorted(missing)}")
        candidates_recipes = [r for r in candidates_recipes if r.name in only]

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
            action = plan_bump(cand, pr_target_branch)
            print(f"             {'sha256:':<8}{action.new_sha256}")

            if mode >= Mode.edit:
                edit_bump(action, dry_run=dry_run)
            if mode == Mode.submit:
                submit_bump(action, dry_run=dry_run)
                if not dry_run:
                    print(f"             opened PR: {action.pr_title}")
        except Exception as e:
            print(f"  {'error':<7}  {recipe.name}: {e}")
            continue

        total += 1
        if pr_limit is not None and total >= pr_limit:
            break

    print(f"Total ({mode.value}): {total}")
    if dry_run:
        print("=" * 72)
        print("  DRY RUN complete — nothing was actually executed")
        print("=" * 72)

