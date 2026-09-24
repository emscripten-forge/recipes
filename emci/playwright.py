import re
from pathlib import Path
from typing import Optional

from .find_recipes_with_changes import find_recipes_with_changes


PLAYWRIGHT_PATTERNS = [
    re.compile(r"^\s*-?\s*script:\s*pytester\b", re.MULTILINE),
    re.compile(r"playwright\s+install"),
    re.compile(r"microsoft::playwright"),
]


def recipe_needs_playwright(recipe_yaml: str) -> bool:
    return any(pattern.search(recipe_yaml) for pattern in PLAYWRIGHT_PATTERNS)


def changed_recipes_need_playwright(
    old: str, new: str, subdir: Optional[str] = None
) -> bool:
    for current_subdir, recipes in find_recipes_with_changes(
        old=old, new=new, subdir=subdir
    ).items():
        for recipe in recipes:
            meta_path = Path("recipes") / current_subdir / recipe / "recipe.yaml"
            if not meta_path.is_file():
                continue
            if recipe_needs_playwright(meta_path.read_text()):
                return True
    return False
