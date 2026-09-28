"""Sync recipe changes from main onto a migration branch (e.g. emscripten-6x)."""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from .git_utils import (
    find_files_with_changes,
    get_current_branch_name,
    make_pr,
    set_bot_user,
)

ON_GITHUB_ACTIONS = os.environ.get("GITHUB_ACTIONS") == "true"

# Only recipes_emscripten on main is synced. On the migration branch a recipe may
# live under recipes_wasm (migrated) or recipes_emscripten (not yet migrated).
MAIN_RECIPES_SUBDIR = "recipes_emscripten"
MAIN_RECIPES_PREFIX = f"recipes/{MAIN_RECIPES_SUBDIR}/"
MIGRATION_ROOTS = ("recipes/recipes_wasm", "recipes/recipes_emscripten")


def _main_recipe_path(recipe: str) -> str:
    return f"{MAIN_RECIPES_PREFIX}{recipe}"


def _short_sha(ref: str) -> str:
    return (
        subprocess.check_output(["git", "rev-parse", "--short", ref])
        .decode("utf-8")
        .strip()
    )


def _commit_message(ref: str) -> str:
    return (
        subprocess.check_output(["git", "log", "-1", "--format=%s", ref])
        .decode("utf-8")
        .strip()
    )


def _recipe_exists_at_ref(ref: str, recipe: str) -> bool:
    result = subprocess.run(
        ["git", "ls-tree", "-d", "--name-only", ref, _main_recipe_path(recipe)],
        check=False,
        capture_output=True,
    )
    return bool(result.stdout.strip())


def _changed_recipes(old: str, new: str) -> list[str]:
    """Return recipe names under recipes_emscripten changed between old and new."""
    recipes: set[str] = set()
    for file_path in find_files_with_changes(old=old, new=new):
        if not file_path.startswith(MAIN_RECIPES_PREFIX):
            continue
        rest = os.path.normpath(file_path[len(MAIN_RECIPES_PREFIX) :])
        recipe = rest.split(os.sep)[0]
        if recipe:
            recipes.add(recipe)
    return sorted(recipes)


def _locate_recipe(recipe: str) -> tuple[Path, bool]:
    """
    Find where a recipe lives on the migration branch.

    Returns (target_path, existed). If missing, target_path is under
    recipes/recipes_emscripten for creation.
    """
    for root in MIGRATION_ROOTS:
        path = Path(root) / recipe
        if path.is_dir():
            return path, True
    return Path(MIGRATION_ROOTS[-1]) / recipe, False


def _add_recipe_from_ref(ref: str, recipe: str) -> Path:
    """Check out a new recipe tree from ref into the working tree (same path as on main)."""
    source = _main_recipe_path(recipe)
    print(f"Checking out {source} from {ref}")
    subprocess.check_output(["git", "checkout", ref, "--", source])
    return Path(source)


def _diff_for_recipe(old: str, new: str, recipe: str) -> bytes:
    """Return the binary-capable diff for one recipe between old and new."""
    return subprocess.check_output(
        ["git", "diff", "--binary", old, new, "--", _main_recipe_path(recipe)]
    )


def _rewrite_diff_paths(diff: bytes, from_prefix: str, to_prefix: str) -> bytes:
    """Rewrite recipe path prefixes in a unified/binary diff."""
    if not diff or from_prefix == to_prefix:
        return diff
    text = diff.decode("utf-8", errors="surrogateescape")
    return text.replace(from_prefix, to_prefix).encode(
        "utf-8", errors="surrogateescape"
    )


def _apply_recipe_diff(diff: bytes) -> tuple[bool, str]:
    """
    Apply a patch with ``git apply --reject``.

    Returns (any_changes_in_worktree, reject_text). Reject ``.rej`` files are
    read then deleted so they are not committed.
    """
    if not diff.strip():
        return False, ""

    with tempfile.NamedTemporaryFile(suffix=".patch", delete=False) as patch_file:
        patch_file.write(diff)
        patch_path = patch_file.name

    try:
        before = subprocess.check_output(
            ["git", "status", "--porcelain"]
        ).decode("utf-8")
        result = subprocess.run(
            ["git", "apply", "--reject", "--whitespace=nowarn", patch_path],
            capture_output=True,
        )
        stderr = result.stderr.decode("utf-8", errors="replace")
        stdout = result.stdout.decode("utf-8", errors="replace")
        if stdout.strip():
            print(stdout.rstrip())
        if result.returncode != 0:
            print(f"git apply exited {result.returncode}")
            if stderr.strip():
                print(stderr.rstrip())

        reject_chunks: list[str] = []
        for rej_path in sorted(Path(".").rglob("*.rej")):
            try:
                reject_chunks.append(
                    f"`{rej_path.as_posix()}`\n\n```\n"
                    f"{rej_path.read_text(errors='replace')}```"
                )
            finally:
                rej_path.unlink(missing_ok=True)

        after = subprocess.check_output(
            ["git", "status", "--porcelain"]
        ).decode("utf-8")
        changed = before != after
        return changed, "\n\n".join(reject_chunks)
    finally:
        os.unlink(patch_path)


def _parse_migration_ref(migration_ref: str) -> tuple[str, str]:
    """Parse ``remote/branch`` or ``branch`` (defaults remote to ``origin``)."""
    if "/" in migration_ref:
        remote, branch = migration_ref.split("/", 1)
        if not remote or not branch:
            raise ValueError(
                "migration ref must be 'remote/branch' or 'branch' "
                f"(e.g. upstream/emscripten-6x or emscripten-6x), got {migration_ref!r}"
            )
        return remote, branch
    if not migration_ref:
        raise ValueError("migration ref must not be empty")
    return "origin", migration_ref


def _checkout_migration_branch(remote: str, branch: str) -> None:
    current = get_current_branch_name()
    print(f"Switching from {current} to {remote}/{branch}")
    subprocess.run(["git", "stash"], check=False)
    subprocess.check_output(["git", "fetch", remote, branch])
    subprocess.check_output(["git", "checkout", "-B", branch, f"{remote}/{branch}"])
    print(f"Checked out {branch} from {remote}/{branch}")


def _build_pr_body(
    commit_sha: str,
    migration_branch: str,
    updated: list[tuple[str, Path]],
    added: list[tuple[str, Path]],
    deleted: list[tuple[str, Path]],
) -> str:
    body_lines = [
        f"Automated sync of recipe changes from {commit_sha} onto `{migration_branch}`.",
        "",
    ]
    if updated:
        body_lines.append("### Updated")
        for recipe, path in updated:
            body_lines.append(
                f"- `{recipe}` (`{MAIN_RECIPES_PREFIX}` → `{path}`)"
            )
        body_lines.append("")
    if added:
        body_lines.append("### Added")
        for recipe, path in added:
            body_lines.append(
                f"- `{recipe}` (`{MAIN_RECIPES_PREFIX}` → `{path}`)"
            )
        body_lines.append("")
    if deleted:
        body_lines.append("### Deleted")
        for recipe, path in deleted:
            body_lines.append(f"- `{recipe}` (removed `{path}`)")
        body_lines.append("")
    return "\n".join(body_lines).strip() + "\n"


def sync_migration_branch(
    migration_ref: str,
    old: str,
    new: str,
    dry_run: bool = False,
) -> None:
    """
    Sync recipes_emscripten changes between old and new onto a migration branch
    and open one PR.

    migration_ref must be ``remote/branch`` (e.g. ``upstream/emscripten-6x``)
    or ``branch`` (defaults to ``origin/branch``).
    If dry_run is True, apply file changes on a new branch but do not commit or open a PR;
    print the PR title and body instead.
    """
    remote, migration_branch = _parse_migration_ref(migration_ref)
    print(
        f"Syncing recipe changes {old}...{new} onto {migration_branch} "
        f"(from {remote}/{migration_branch})"
    )
    if dry_run:
        print("Dry run: apply file changes on a new branch but do not commit or open a PR")

    changed = _changed_recipes(old, new)
    if not changed:
        print("No recipe changes to sync")
        return

    print(f"Found {len(changed)} changed recipe(s):")
    for recipe in changed:
        print(f"  - {_main_recipe_path(recipe)}")

    if not dry_run and ON_GITHUB_ACTIONS:
        set_bot_user()

    _checkout_migration_branch(remote, migration_branch)

    short = _short_sha(new)
    branch_name = f"sync-from-main-{short}-to-{migration_branch}"
    pr_title = "[Sync] " + _commit_message(new)

    # New branch from the migration branch tip; PR will target migration_branch.
    subprocess.check_output(["git", "checkout", "-B", branch_name])
    print(f"Created branch {branch_name} from {migration_branch}")

    def _apply_changes() -> tuple[
        list[tuple[str, Path]],
        list[tuple[str, Path]],
        list[tuple[str, Path]],
        list[Path],
        list[tuple[str, Path, str]],
    ]:
        updated: list[tuple[str, Path]] = []
        added: list[tuple[str, Path]] = []
        deleted: list[tuple[str, Path]] = []
        touched_paths: list[Path] = []
        rejects: list[tuple[str, Path, str]] = []

        for recipe in changed:
            target, existed = _locate_recipe(recipe)
            exists_on_new = _recipe_exists_at_ref(new, recipe)

            if not exists_on_new:
                if not existed:
                    print(
                        f"Skip delete for {recipe}: "
                        f"not present on {migration_branch}"
                    )
                    continue
                print(f"Deleting {target} (removed on main)")
                shutil.rmtree(target)
                deleted.append((recipe, target))
                touched_paths.append(target)
                continue

            if not existed:
                dest = _add_recipe_from_ref(new, recipe)
                touched_paths.append(dest)
                added.append((recipe, dest))
                continue

            from_prefix = _main_recipe_path(recipe)
            to_prefix = target.as_posix()
            print(f"Patching {target} from {from_prefix} ({old}..{new})")
            diff = _diff_for_recipe(old, new, recipe)
            rewritten = _rewrite_diff_paths(diff, from_prefix, to_prefix)
            changed_files, reject_text = _apply_recipe_diff(rewritten)
            if reject_text:
                rejects.append((recipe, target, reject_text))
                print(f"Rejects for {target}:\n{reject_text}")
            if changed_files:
                touched_paths.append(target)
                updated.append((recipe, target))
            elif not reject_text:
                print(f"No diff to apply for {target}")

        return updated, added, deleted, touched_paths, rejects

    updated, added, deleted, touched_paths, rejects = _apply_changes()

    if not touched_paths:
        if rejects:
            print(
                "Recipe patch(es) produced only rejects; "
                "no file changes to open a PR with yet"
            )
        else:
            print("Nothing to sync onto the migration branch")
        return

    pr_body = _build_pr_body(new, migration_branch, updated, added, deleted)
    if rejects:
        print(f"Collected rejects for {len(rejects)} recipe(s)")

    if dry_run:
        print("---")
        print(f"PR head branch: {branch_name}")
        print(f"PR base branch: {migration_branch}")
        print(f"PR title: {pr_title}")
        print("PR body:")
        print(pr_body)
        print("---")
        print("Done (dry run); changes are unstaged on this branch")
        return

    print(f"Opening PR: {pr_title}")
    make_pr(
        paths=touched_paths,
        pr_title=pr_title,
        pr_body=pr_body,
        target_branch_name=migration_branch,
        branch_name=branch_name,
    )
    print("Done")
