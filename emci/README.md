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

The sync workflow can perform the following actions:

- **Update:** apply a path-rewritten `git diff` with `git apply --reject`
- **Add:** `git checkout <new> -- recipes/recipes_emscripten/<recipe>`
- **Delete:** remove the located recipe directory
- **Rejects:** included in the PR body; if nothing applies, the recipe build
  number is bumped so the PR is non-empty

To test locally:

- Use `--dry-run` to avoid creating a PR. This creates a new branch and applies
  changes but does not commit or open a PR.
- Use a commit range `<exclusive_hash> <inclusive_hash>` (same as CI:
  `sha~1` … `sha`).

```bash
# python -m emci sync <remote/branch> <oldest_commit_hash> <newest_commit_hash>
python -m emci sync upstream/emscripten-6x d8eff878~1 d8eff878 --dry-run
```

