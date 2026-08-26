"""Sync recipe changes from main onto a migration branch (e.g. emscripten-6x)."""

from __future__ import annotations

import io
import os
import shutil
import subprocess
import tarfile
import tempfile
from pathlib import Path

from .git_utils import (
    find_files_with_changes,
    get_current_branch_name,
    make_pr,
    set_bot_user,
)

ON_GITHUB_ACTIONS = os.environ.get("GITHUB_ACTIONS") == "true"

LINEAGE_ROOTS = {
    "recipes": ("recipes_native", "recipes/recipes"),
    "recipes_emscripten": ("recipes_wasm", "recipes/recipes_emscripten"),
}


def _short_sha(ref: str) -> str:
    return (
        subprocess.check_output(["git", "rev-parse", "--short", ref])
        .decode("utf-8")
        .strip()
    )


def _recipe_exists_at_ref(ref: str, subdir: str, recipe: str) -> bool:
    path = f"recipes/{subdir}/{recipe}"
    result = subprocess.run(
        ["git", "ls-tree", "-d", "--name-only", ref, path],
        check=False,
        capture_output=True,
    )
    return bool(result.stdout.strip())


def _changed_recipes(old: str, new: str) -> list[tuple[str, str]]:
    """Return (subdir, recipe) pairs changed between old and new, including deletions."""
    files_with_changes = find_files_with_changes(old=old, new=new)
    changed: dict[str, set[str]] = {subdir: set() for subdir in LINEAGE_ROOTS}

    for file_path in files_with_changes:
        for subdir in LINEAGE_ROOTS:
            prefix = f"recipes/{subdir}/"
            if file_path.startswith(prefix):
                rest = os.path.normpath(file_path[len(prefix) :])
                recipe = rest.split(os.sep)[0]
                if recipe:
                    changed[subdir].add(recipe)
                break

    result: list[tuple[str, str]] = []
    for subdir, recipes in changed.items():
        for recipe in sorted(recipes):
            result.append((subdir, recipe))
    return result


def _locate_recipe(subdir: str, recipe: str) -> tuple[Path, bool]:
    """
    Find where a recipe lives on the migration branch for its lineage.

    Returns (target_path, existed). If missing, target_path is under the new
    root (recipes_native / recipes_wasm) for creation.
    """
    new_root, legacy_root = LINEAGE_ROOTS[subdir]
    for root in (new_root, legacy_root):
        path = Path(root) / recipe
        if path.is_dir():
            return path, True
    return Path(new_root) / recipe, False


def _replace_recipe_dir_from_ref(ref: str, subdir: str, recipe: str, dest: Path) -> None:
    """Replace dest with the full recipe tree from ref at recipes/<subdir>/<recipe>."""
    source = f"recipes/{subdir}/{recipe}"
    archive = subprocess.check_output(
        ["git", "archive", "--format=tar", ref, source]
    )

    if dest.exists():
        shutil.rmtree(dest)
    dest.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        with tarfile.open(fileobj=io.BytesIO(archive), mode="r:") as tar:
            tar.extractall(tmp, filter="data")
        extracted = Path(tmp) / source
        if not extracted.is_dir():
            raise RuntimeError(f"git archive did not produce directory {source}")
        shutil.move(str(extracted), str(dest))


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
    short: str,
    migration_branch: str,
    updated: list[tuple[str, str, Path]],
    added: list[tuple[str, str, Path]],
    deleted: list[tuple[str, str, Path]],
) -> str:
    body_lines = [
        f"Automated sync of recipe changes from `{short}` onto `{migration_branch}`.",
        "",
    ]
    if updated:
        body_lines.append("### Updated")
        for subdir, recipe, path in updated:
            body_lines.append(f"- `{recipe}` (`recipes/{subdir}/` → `{path}`)")
        body_lines.append("")
    if added:
        body_lines.append("### Added")
        for subdir, recipe, path in added:
            body_lines.append(f"- `{recipe}` (`recipes/{subdir}/` → `{path}`)")
        body_lines.append("")
    if deleted:
        body_lines.append("### Deleted")
        for subdir, recipe, path in deleted:
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
    Sync recipes changed between old and new onto a migration branch and open one PR.

    migration_ref must be ``remote/branch`` (e.g. ``upstream/emscripten-6x``)
    or ``branch`` (defaults to ``origin/branch``).
    If dry_run is True, do not modify files or open a PR; print the PR title and body.
    """
    remote, migration_branch = _parse_migration_ref(migration_ref)
    print(
        f"Syncing recipe changes {old}...{new} onto {migration_branch} "
        f"(from {remote}/{migration_branch})"
    )
    if dry_run:
        print("Dry run: no files will be changed and no PR will be opened")

    changed = _changed_recipes(old, new)
    if not changed:
        print("No recipe changes to sync")
        return

    print(f"Found {len(changed)} changed recipe(s):")
    for subdir, recipe in changed:
        print(f"  - recipes/{subdir}/{recipe}")

    if not dry_run and ON_GITHUB_ACTIONS:
        set_bot_user()

    _checkout_migration_branch(remote, migration_branch)

    short = _short_sha(new)
    branch_name = f"sync-from-main-{short}-to-{migration_branch}"
    pr_title = f"Sync recipes from main ({short}) [{migration_branch}]"

    # New branch from the migration branch tip; PR will target migration_branch.
    subprocess.check_output(["git", "checkout", "-B", branch_name])
    print(f"Created branch {branch_name} from {migration_branch}")

    def _plan_and_maybe_apply() -> tuple[
        list[tuple[str, str, Path]],
        list[tuple[str, str, Path]],
        list[tuple[str, str, Path]],
        list[Path],
    ]:
        updated: list[tuple[str, str, Path]] = []
        added: list[tuple[str, str, Path]] = []
        deleted: list[tuple[str, str, Path]] = []
        touched_paths: list[Path] = []

        for subdir, recipe in changed:
            target, existed = _locate_recipe(subdir, recipe)
            exists_on_new = _recipe_exists_at_ref(new, subdir, recipe)

            if not exists_on_new:
                if not existed:
                    print(
                        f"Skip delete for {recipe} ({subdir}): "
                        f"not present on {migration_branch}"
                    )
                    continue
                print(f"{'Would delete' if dry_run else 'Deleting'} {target} (removed on main)")
                if not dry_run:
                    shutil.rmtree(target)
                deleted.append((subdir, recipe, target))
                touched_paths.append(target)
                continue

            if dry_run:
                action = "Would update" if existed else "Would add"
            else:
                action = "Updating" if existed else "Adding"
            print(f"{action} {target} from recipes/{subdir}/{recipe}@{new}")
            if not dry_run:
                _replace_recipe_dir_from_ref(new, subdir, recipe, target)
            touched_paths.append(target)
            if existed:
                updated.append((subdir, recipe, target))
            else:
                added.append((subdir, recipe, target))

        return updated, added, deleted, touched_paths

    updated, added, deleted, touched_paths = _plan_and_maybe_apply()

    if not touched_paths:
        print("Nothing to sync onto the migration branch")
        return

    pr_body = _build_pr_body(short, migration_branch, updated, added, deleted)

    if dry_run:
        print("---")
        print(f"PR head branch: {branch_name}")
        print(f"PR base branch: {migration_branch}")
        print(f"PR title: {pr_title}")
        print("PR body:")
        print(pr_body)
        print("---")
        print("Done (dry run)")
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
