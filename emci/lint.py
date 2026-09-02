import fnmatch
import sys
from pathlib import Path

import yaml
from pydantic import ValidationError

from .find_recipes_with_changes import find_recipes_with_changes
from .schema import Recipe

EXPERIMENTAL_CHANNEL_PATTERN = "emscripten-forge-*-experimental"


def is_experimental_recipe(recipe_data: dict) -> bool:
    channel = recipe_data.get("extra", {}).get("channel", "")
    return fnmatch.fnmatch(channel, EXPERIMENTAL_CHANNEL_PATTERN)


def normalize_source(source):
    if isinstance(source, list) and len(source) == 1:
        return source[0]
    return source


def load_recipe_yaml(path: Path) -> dict:
    with open(path) as f:
        meta = yaml.safe_load(f)
    if meta is None:
        raise ValueError(f"{path} is empty or not valid YAML")
    if "source" in meta:
        meta["source"] = normalize_source(meta["source"])
    return meta


def resolve_recipe_path(path: Path) -> Path:
    path = path.resolve()
    if path.is_dir():
        path = path / "recipe.yaml"
    if not path.exists():
        raise FileNotFoundError(f"recipe.yaml not found at {path}")
    if path.name != "recipe.yaml":
        raise ValueError(f"Expected recipe.yaml, got {path.name}")
    return path


def _clean_pydantic_msg(msg: str) -> str:
    for prefix in ("Value error, ", "Assertion failed, ", "AttributeError, "):
        if msg.startswith(prefix):
            return msg.removeprefix(prefix)
    return msg


def _format_validation_error(exc: Exception) -> str:
    if isinstance(exc, ValidationError):
        parts = []
        for error in exc.errors():
            loc = ".".join(str(part) for part in error["loc"])
            msg = _clean_pydantic_msg(error["msg"])
            if error["type"] == "missing":
                parts.append(f"Missing required field '{loc}'")
            elif msg.startswith("source."):
                parts.append(msg)
            elif loc:
                parts.append(f"{loc}: {msg}")
            else:
                parts.append(msg)
        return "; ".join(parts)
    return str(exc)


def _validate_recipe(meta_path: Path, meta: dict, display_name: str | None = None) -> bool:
    name = display_name or meta_path.parent.name
    channel = meta.get("extra", {}).get("channel")
    if is_experimental_recipe(meta):
        print(f"⏭️ {name} skipped (experimental channel: {channel})")
        return True

    try:
        Recipe.model_validate(meta)
        print(f"✅ {name} passed validation")
        return True
    except Exception as e:
        print(f"❌ {name} failed validation: {_format_validation_error(e)}")
        return False


def lint_recipe_file(path: Path) -> bool:
    try:
        meta_path = resolve_recipe_path(path)
        meta = load_recipe_yaml(meta_path)
    except Exception as e:
        print(f"❌ Failed to parse {path}: {e}")
        return False
    return _validate_recipe(meta_path, meta)


def lint_recipes(old: str, new: str) -> None:
    recipes_with_changes_per_subdir = find_recipes_with_changes(old=old, new=new)

    failed = False
    for subdir, recipe_with_changes in recipes_with_changes_per_subdir.items():
        for recipe in recipe_with_changes:
            meta_path = Path("recipes") / subdir / recipe / "recipe.yaml"
            if not meta_path.exists():
                print(f"⚠️ Skipping {meta_path}, file not found")
                continue

            if not lint_recipe_file(meta_path):
                failed = True

    if failed:
        print("❌ One or more recipes failed validation")
        sys.exit(1)

    print("✅ All changed recipes passed validation")
