"""Order changed recipes so producers are built before their consumers.

`rattler-build build --recipe-dir` sorts the recipes of a directory by
dependency, but its graph ignores requirements declared on `staging:` outputs
and ignores `run:` requirements (verified with the version pinned in
`ci_env.yml`, 0.67.0): a recipe whose dependency lives in its staging output is
built *before* the producer and dies with
`Cannot solve the request because of: No candidates were found for <pkg>`.
Consumers of a `-dev` split (`arrow` -> `thrift-cpp-dev`, `python-symengine` ->
`symengine-dev`, `pygplates-experimental` -> `cgal-cpp-dev`) are exactly that
shape, so emci builds one recipe per rattler-build invocation, in the order
computed here (each invocation sees the artifacts of the previous ones).
"""

from __future__ import annotations

import os
import re
import sys
from typing import Iterable

import yaml

# package specs look like: "python 3.13.* *_cp313", "thrift-cpp-dev =0.22.0"
_NAME_RE = re.compile(r"^\s*([A-Za-z0-9_.\-]+)")
_PIN_SUBPACKAGE_RE = re.compile(r"pin_subpackage\(\s*['\"]([^'\"]+)['\"]")


def _load(recipe_dir: str) -> dict | None:
    path = os.path.join(recipe_dir, "recipe.yaml")
    if not os.path.isfile(path):
        return None
    with open(path) as handle:
        return yaml.safe_load(handle) or {}


def provided_names(recipe: dict) -> set[str]:
    """Every package name a recipe can provide (its outputs plus context name)."""
    names: set[str] = set()
    package = recipe.get("package") or {}
    if isinstance(package.get("name"), str):
        names.add(package["name"])
    context = recipe.get("context") or {}
    if isinstance(context.get("name"), str):
        # templates such as `name: ${{ name }}` resolve to the context name
        names.add(context["name"])
    for output in recipe.get("outputs") or []:
        name = (output.get("package") or {}).get("name")
        if isinstance(name, str):
            names.add(name)
    return names


def referenced_names(recipe: dict) -> set[str]:
    """Package names referenced from any output, staging outputs included."""
    requirements_blocks = [recipe.get("requirements") or {}]
    for output in recipe.get("outputs") or []:
        requirements_blocks.append(output.get("requirements") or {})

    names: set[str] = set()
    for block in requirements_blocks:
        for section in ("build", "host", "run"):
            for spec in block.get(section) or []:
                spec = str(spec)
                match = _NAME_RE.match(spec)
                if match:
                    names.add(match.group(1))
                names.update(_PIN_SUBPACKAGE_RE.findall(spec))
    return names


def sort_recipes_by_dependency(recipes_root: str, recipes: Iterable[str]) -> list[str]:
    """Topological order of `recipes` (producers first, alphabetical otherwise)."""
    recipes = sorted(recipes)
    provided = {}
    referenced = {}
    for name in recipes:
        recipe = _load(os.path.join(recipes_root, name)) or {}
        provided[name] = provided_names(recipe)
        referenced[name] = referenced_names(recipe)

    # producer -> consumers
    dependencies = {name: set() for name in recipes}
    for consumer in recipes:
        for referenced_name in referenced[consumer]:
            for producer, names in provided.items():
                if producer != consumer and referenced_name in names:
                    dependencies[consumer].add(producer)

    ordered: list[str] = []
    done: set[str] = set()
    remaining = list(recipes)
    while remaining:
        ready = [name for name in remaining if dependencies[name] <= done]
        # a cycle would block everything: emit the first name instead of looping
        batch = ready if ready else [remaining[0]]
        for name in batch:
            ordered.append(name)
            done.add(name)
            remaining.remove(name)
    return ordered


def main(argv: list[str]) -> int:
    """Print the build order for a recipes directory (self-check)."""
    if len(argv) < 2:
        print(f"usage: {sys.argv[0]} <recipes_dir> [names...]", file=sys.stderr)
        return 2
    recipes_root, names = argv[1], argv[2:]
    if not names:
        names = [
            name
            for name in os.listdir(recipes_root)
            if os.path.isfile(os.path.join(recipes_root, name, "recipe.yaml"))
        ]
    print("\n".join(sort_recipes_by_dependency(recipes_root, names)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
