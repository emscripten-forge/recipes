# Testing locally

## Requirements

- Create and activate environment from the [ci_env.yml](../ci_env.yml) file.

## Test linter

```bash
# Lint changed recipes between two git refs
python -m emci lint upstream/main HEAD

# Lint a single recipe
python -m emci lint --file recipes/recipes_emscripten/numpy/recipe.yaml
python -m emci lint --file recipes/recipes_emscripten/numpy
```


## Test sync

- Use `--dry-run` to avoid creating a PR. This will create a new branch and apply the changes, but it will not commit the changes.
- Use a commit range `<exclusive_hash> <inclusive_hash>`

```bash
# python -m emci sync <remote/branch> <oldest_commit_hash> <newest_commit_hash>
python -m emci sync upstream/emscripten-6x d6fa19a491adde2585fd4fe4ca8be6dd154cfc90~1 d6fa19a491adde2585fd4fe4ca8be6dd154cfc90 --dry-run
```

