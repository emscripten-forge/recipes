#!/usr/bin/env python3
"""Vendor boostdep's module dependency report as scripts/boostdep_deps.json.

One-time (per Boost release) step, run OUTSIDE the recipe build, it needs
network + a built boostdep binary. gen_boost_deps.py only ever reads the
vendored JSON, so recipe builds stay hermetic.

  git clone --depth 1 --branch boost-1.92.0 --recurse-submodules \\
      --shallow-submodules https://github.com/boostorg/boost.git ~/boost-1.92.0
  cd ~/boost-1.92.0 && ./bootstrap.sh && ./b2 tools/boostdep/build
  python3 gen_boostdep_deps.py --boost-root ~/boost-1.92.0 \\
      --boostdep ~/boost-1.92.0/dist/bin/boostdep

Keys are boostdep's own module names (--list-modules minus the 'headers'
pseudo-module, e.g. 'numeric~conversion'); gen_boost_deps.py maps them to
package names and include paths.

  modules    boostdep's module universe == our package set
  deps       module -> direct header deps (--no-track-sources: what header
             consumers need; source-level deps are link concerns)
  buildable  module -> direct deps among buildable modules
             (--list-buildable-dependencies: includes source-level deps,
             so it is the link closure oracle)
"""
from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
NON_MODULES = {"headers", "(unknown)"}


def run(boostdep: Path, root: Path, *args: str) -> str:
    return subprocess.run([str(boostdep), "--boost-root", str(root), *args],
                          check=True, capture_output=True, text=True).stdout


def modules(boostdep: Path, root: Path) -> set[str]:
    """boostdep's module universe, minus the 'headers' pseudo-module."""
    return set(run(boostdep, root, "--list-modules").split()) - NON_MODULES


def report(boostdep: Path, root: Path, *args: str) -> dict[str, set[str]]:
    """Parse a boostdep overview report ('mod -> deps' or 'mod = deps ;')."""
    res: dict[str, set[str]] = {}
    for line in run(boostdep, root, *args).splitlines():
        if "->" in line:
            mod, deps = line.split("->", 1)
        elif "=" in line:
            mod, deps = line.split("=", 1)
            deps = deps.split(";", 1)[0]
        else:
            continue
        res[mod.strip()] = set(deps.split())
    return res


def git(root: Path, *args: str) -> str:
    return subprocess.run(["git", "-C", str(root), *args],
                          check=True, capture_output=True, text=True).stdout.strip()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--boost-root", required=True, help="boost git checkout at the release tag")
    ap.add_argument("--boostdep", required=True, help="path to the boostdep binary")
    ap.add_argument("--out", default=str(HERE / "boostdep_deps.json"))
    a = ap.parse_args()
    root, boostdep = Path(a.boost_root).resolve(), Path(a.boostdep).resolve()
    mods = modules(boostdep, root)
    hdeps = report(boostdep, root, "--no-track-sources", "--list-dependencies")
    bdeps = report(boostdep, root, "--list-buildable-dependencies")
    strays = sorted({d for r in (hdeps, bdeps) for v in r.values() for d in v}
                    - mods - NON_MODULES)
    data = {
        "_meta": {
            "boost_tag": git(root, "describe", "--tags"),
            "commit": git(root, "rev-parse", "HEAD"),
            "tool": "boostdep --list-dependencies --no-track-sources + --list-buildable-dependencies",
            "source": "https://github.com/boostorg/boost tools/boostdep",
        },
        "modules": sorted(mods),
        "deps": {m: sorted(hdeps.get(m, set()) & mods) for m in sorted(mods)},
        "buildable": {m: sorted(bdeps.get(m, set()) & mods) for m in sorted(mods)},
    }
    Path(a.out).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    print(f"wrote {a.out}: {len(mods)} modules, "
          f"{sum(len(v) for v in data['deps'].values())} header deps, "
          f"{sum(len(v) for v in data['buildable'].values())} buildable deps, "
          f"strays: {strays or 'none'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
