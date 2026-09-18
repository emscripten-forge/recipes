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

## Test version-bump bot

The bot has two independent subcommands. CI runs them in sequence; locally you
can invoke either on its own.

### `bump-recipes-versions` — open new bump PRs

Runs in four ordered *modes*. Each mode does its own stage plus every earlier
one — pick the deepest stage you want to reach. Default is `check` (safe,
read-only preview).

| Mode     | Adds                                                                       |
|----------|----------------------------------------------------------------------------|
| `check`  | HEAD candidate URLs until one exists. No downloads.                        |
| `plan`   | + download the winning tarball and print `sha256`.                         |
| `edit`   | + create a local branch, write `recipe.yaml`, commit (no push).            |
| `submit` | + push the branch and open the PR. This is what CI runs.                   |

`--dry-run` is orthogonal to `--mode`: it turns every write / git / gh command
into a `[dry] would run ...` line and prints the recipe.yaml diff instead of
writing it. Reads (HEADs, `gh pr list`) still happen so decisions are made
against real state. Combine with any mode: `--mode submit --dry-run` is a full
rehearsal that touches nothing.

Other flags:

- `--limit N` — stop after this many recipes with a bump available (default `20`).
- `--recipe NAME` — only consider these recipes (repeatable). Implies "no
  repo-wide skipping of recipes with existing PRs" — you asked for these
  specifically.

```bash
# Fast inventory of what could bump (default --mode check)
python -m emci bot bump-recipes-versions main

# Same, but only one recipe
python -m emci bot bump-recipes-versions main --recipe cramjam

# Add hash download to get the exact sha256 that would be committed
python -m emci bot bump-recipes-versions main --mode plan --recipe cramjam --limit 3

# Full pipeline rehearsal — prints every git/gh command the real run would issue,
# no writes / no branches / no PRs. Includes the recipe.yaml diff for edit stage.
python -m emci bot bump-recipes-versions main --mode submit --dry-run

# Create the local branch and commit, but do not push
python -m emci bot bump-recipes-versions main --mode edit --recipe cramjam
#   inspect the produced branch:
git log bump-cramjam_<old>_to_<new>_for_main
git diff main..bump-cramjam_<old>_to_<new>_for_main
#   clean up when done:
git branch -D bump-cramjam_<old>_to_<new>_for_main

# Real run — opens PRs (only run intentionally):
python -m emci bot bump-recipes-versions main --mode submit
```

### `merge-open-prs` — merge / label already-open bot PRs

Reviews the bot's own currently-open PRs on the target branch. Green ones with
`Automerge` get merged; the rest get a `Needs Human Review` label and a bot
comment (updates the last bot comment rather than posting a new one). Does not
touch any recipe or open any new PR.

Reads (`gh pr list`, `gh pr checks`, `gh pr view --json labels`) always run —
they're needed to decide what to do. Mutations honour `--dry-run`.

```bash
# Rehearse the merge/label pass
python -m emci bot merge-open-prs main --dry-run

# Do it for real (this is what CI runs first)
python -m emci bot merge-open-prs main
```

