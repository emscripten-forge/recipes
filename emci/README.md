# Testing locally

## Requirements

- Create and activate environment from the [ci_env.yml](../ci_env.yml) file.

## Test linter

```bash
# python -m emci build lint <old> <new>
python -m emci build lint upstream/main HEAD
```


## Test sync

- Use `--dry-run` to avoid creating a PR. This will create a new branch and apply the changes, but it will not commit the changes.
- Use a commit range `<exclusive_hash> <inclusive_hash>`

```bash
# python -m emci sync <remote/branch> <oldest_commit_hash> <newest_commit_hash>
python -m emci sync upstream/emscripten-6x d6fa19a491adde2585fd4fe4ca8be6dd154cfc90~1 d6fa19a491adde2585fd4fe4ca8be6dd154cfc90 --dry-run
```

