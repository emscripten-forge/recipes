#!/usr/bin/env python3
"""Generate the boost-cpp multi-output recipe (one conda package per Boost module).

Usage:
  gen_boost_deps.py <boost-root> [out-dir]
    <boost-root>  Boost git checkout with submodules: libs/<m>/include/
                  present plus the merged boost/ tree from `./b2 headers`.
                  NOT a release tarball: those ship no libs/<m>/include/, so
                  module ownership cannot be derived.
    out-dir       default: scripts/out (relative to this file)
Writes out-dir/deps.json, out-dir/recipe_outputs.yaml (PyYAML required).
Test .cpp files are NEVER generated: they live hand-authored, flat, in
tests/test_<module>.cpp. The generated region of recipe.yaml must be kept
byte-identical to recipe_outputs.yaml: run the splice step below, then re-run
this script, which asserts the two are identical and exits non-zero otherwise.

Splice step (one-time after recipe.yaml structural edits):
  replace everything between the '# >>> generated' and '# <<< generated' lines
  (inclusive) with the content of out-dir/recipe_outputs.yaml.
"""

from __future__ import annotations

import graphlib
import json
import os
import re
import sys
from pathlib import Path
from typing import Iterator

import yaml

HERE = Path(__file__).resolve().parent
OUT_DEFAULT = HERE / "out"
BOOSTDEP_FILE = HERE / "boostdep_deps.json"  # vendored by gen_boostdep_deps.py
SKIP_FILE = HERE.parent / "build.sh"  # BOOST_SKIP_MODULES="..." single source of truth

ModuleKey = str          # boostdep module name ('filesystem', 'numeric~interval', ...)
PkgName = str            # conda package name ('boost-filesystem', ...)
Claim = str              # 'include/boost/<path>[/**]' package-content entry

INC_RE = re.compile(r'#\s*include\s*[<"](boost/[A-Za-z0-9_./]+)[>"]')
HEADER_SUFFIXES = (".hpp", ".h", ".ipp")

OWN_LIBS: dict[ModuleKey, list[str]] = {
    "math": ["boost_math_c99", "boost_math_c99f", "boost_math_tr1", "boost_math_tr1f"],
    "test": ["boost_unit_test_framework", "boost_prg_exec_monitor",
             "boost_test_exec_monitor"],
    "serialization": ["boost_serialization", "boost_wserialization"],
}
LIB_FILES: dict[ModuleKey, list[str]] = {
    m: [f"lib/lib{s}.a" for s in stems] for m, stems in OWN_LIBS.items()
}
EXTRA_ARCH: dict[ModuleKey, list[str]] = {"iostreams": ["libz.a", "libbz2.a"]}  # external static libs at test link
EXTRA_RUN: dict[ModuleKey, list[str]] = {"iostreams": ["zlib", "bzip2"]}  # conda pkgs shipping those libs


def pkg_of(key: ModuleKey) -> PkgName:
    """conda package name for a boostdep module key ('numeric~interval' ->
    boost-numeric_interval)."""
    return f"boost-{key.replace('~', '_')}"


def cfg_path(base: str) -> Claim:
    return f"lib/cmake/boost_{base}/boost_{base}Config.cmake"


def archive_of(mod: ModuleKey) -> str:
    stem = OWN_LIBS.get(mod, [mod])[0]
    return f"lib{stem if stem.startswith('boost_') else 'boost_' + stem}.a"


def skip_from_build_sh() -> set[ModuleKey]:
    m = re.search(r'BOOST_SKIP_MODULES="([^"]*)"', SKIP_FILE.read_text())
    assert m, f"BOOST_SKIP_MODULES not found in {SKIP_FILE}"
    return set(m.group(1).split())


def load_boostdep() -> tuple[list[ModuleKey], dict[ModuleKey, set[ModuleKey]],
                             dict[ModuleKey, set[ModuleKey]]]:
    """(modules, header deps, buildable deps) from the vendored report.

    Reads the vendored boostdep report (gen_boostdep_deps.py). The report is
    per-release data: refuse to run against a bumped recipe version.
    """
    data = json.loads(BOOSTDEP_FILE.read_text())
    ctx = yaml.safe_load((HERE.parent / "recipe.yaml").read_text())["context"]
    want = f"boost-{ctx['version']}"
    assert data["_meta"]["boost_tag"] == want, \
        f"stale {BOOSTDEP_FILE.name}: {data['_meta']['boost_tag']} != {want}"
    modules: list[ModuleKey] = data["modules"]
    deps = {m: set(v) for m, v in data["deps"].items()}
    buildable = {m: set(v) for m, v in data["buildable"].items()}
    assert set(deps) == set(buildable) == set(modules), "report module set mismatch"
    return modules, deps, buildable


def parse_exceptions(root: Path, modules: set[ModuleKey]) -> dict[ModuleKey, list[str]]:
    exc_file = root / "tools" / "boostdep" / "depinst" / "exceptions.txt"
    extra: dict[ModuleKey, list[str]] = {}
    mod: ModuleKey | None = None
    for line in exc_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if not line.startswith("boost/"):
            mod = line.rstrip(":").replace("/", "~")
            continue
        if mod in modules:
            extra.setdefault(mod, []).append(line.removeprefix("boost/"))
    return extra


def build_ownership(root: Path, modules: list[ModuleKey]) -> tuple[dict[str, ModuleKey],
                                                                   dict[ModuleKey, list[str]]]:
    """(rel path below boost/ -> module, module -> sorted rel paths).

    A module owns its libs/<m>/include/boost tree plus the exceptions.txt
    assignments (exceptions win where both apply); together they cover the
    merged boost/ tree exactly, else this dies.
    """
    exc = parse_exceptions(root, set(modules))
    owner: dict[str, ModuleKey] = {p: m for m, ps in exc.items() for p in ps}
    for m in modules:
        inc = root / "libs" / m.replace("~", "/") / "include" / "boost"
        for p in walk_files(inc):
            rel = p.relative_to(inc).as_posix()
            prev = owner.setdefault(rel, m)
            if prev != m:
                raise SystemExit(f"double ownership: {rel}: {prev} vs {m}")
    merged = {p.relative_to(root / "boost").as_posix() for p in walk_files(root / "boost")}
    if set(owner) != merged:
        raise SystemExit(f"ownership mismatch: unowned {len(merged - set(owner))}, "
                         f"phantom {len(set(owner) - merged)}")
    files: dict[ModuleKey, list[str]] = {m: [] for m in modules}
    for rel, m in owner.items():
        files[m].append(rel)
    for fs in files.values():
        fs.sort()
    empty = [m for m in modules if not files[m]]
    if empty:
        raise SystemExit(f"modules with no files: {empty}")
    return owner, files


def claims_for(files: list[str], boost_dir: Path) -> list[Claim]:
    """Sorted include/boost/... entries for one module.

    A top-level entry becomes a glob when the module owns every physical file
    below it, an explicit file list when it shares it with another module
    (boost/detail/**, boost/numeric/**, ...).
    """
    groups: dict[str, list[str]] = {}
    for rel in files:
        groups.setdefault(rel.split("/", 1)[0], []).append(rel)
    entries: list[Claim] = []
    for top, rels in sorted(groups.items()):
        base = boost_dir / top
        if base.is_file():
            entries.append(f"include/boost/{top}")
        elif len(rels) == sum(1 for _ in walk_files(base)):
            entries.append(f"include/boost/{top}/**")
        else:
            entries += [f"include/boost/{r}" for r in rels]
    return entries


def owner_of(owner: dict[str, ModuleKey], target: str) -> ModuleKey | None:
    """Module owning one include target ('.hpp' optional)."""
    return owner.get(target) or owner.get(f"{target}.hpp")


def walk_files(base: Path) -> Iterator[Path]:
    """Every file below base, following directory symlinks.

    `b2 headers` builds the merged boost/ tree out of symlinks and pathlib's
    `**` does not descend into symlinked dirs; os.walk(followlinks=True) does.
    """
    for dirpath, _dirs, names in os.walk(base, followlinks=True):
        for name in names:
            if name.startswith("."):  # .gitkeep/.gitignore are repo plumbing, not headers
                continue
            p = Path(dirpath) / name
            if not p.is_file():
                continue
            yield p


def iter_includes(text: str) -> Iterator[str]:
    """Include targets below boost/, without the .hpp suffix.

    Line comments are stripped first: a commented-out include is not a
    dependency.
    """
    for line in text.splitlines():
        for inc in INC_RE.findall(line.split("//", 1)[0]):
            yield inc.removeprefix("boost/").removesuffix(".hpp")


def topo_order(nodes: list[ModuleKey], edges: dict[ModuleKey, set[ModuleKey]]) \
        -> tuple[list[ModuleKey], set[tuple[ModuleKey, ModuleKey]]]:
    """Deps-first Kahn order over run-dep edges.

    Residual include cycles (real mutual textual deps, e.g. detail/algorithm
    <-> range/*) cannot be ordered: drop the alphabetically-last edge of each
    cycle. Callers must remove those edges from the package run lists too
    (the package built first in a pair would otherwise declare the second as
    a run dep and its eagerly-solved test env could not resolve).
    """
    edges = {n: set(ds) for n, ds in edges.items()}
    broken: set[tuple[ModuleKey, ModuleKey]] = set()
    while True:
        color: dict[ModuleKey, int] = {}
        cyc: list[ModuleKey] = []

        def find_cycle(n: ModuleKey, trail: list[ModuleKey]) -> list[ModuleKey] | None:
            color[n] = 1
            trail.append(n)
            for d in sorted(edges.get(n, ())):
                if color.get(d, 0) == 1:
                    return trail[trail.index(d):]
                if color.get(d, 0) == 0:
                    found = find_cycle(d, trail)
                    if found:
                        return found
            trail.pop()
            color[n] = 2
            return None

        for n in sorted(nodes):
            if color.get(n, 0) == 0 and (cyc := find_cycle(n, []) or []):
                break
        if not cyc:
            break
        src = max(cyc[:-1])  # drop the alphabetically-last edge of the cycle
        dst = cyc[cyc.index(src) + 1]
        edges[src].discard(dst)
        broken.add((src, dst))
    assert len(broken) < 25, f"suspicious number of order breaks: {sorted(broken)}"

    ts = graphlib.TopologicalSorter(edges)
    ts.prepare()
    ready = sorted(ts.get_ready())
    order: list[ModuleKey] = []
    while ready:
        n = ready.pop(0)
        order.append(n)
        ts.done(n)
        ready += ts.get_ready()
        ready.sort()
    leftover = sorted(set(nodes) - set(order))
    assert not leftover, (
        f"could not order outputs: {len(order)} ordered, leftover "
        f"{leftover[:8]} ... (count {len(leftover)})")
    return order, broken


class _Dumper(yaml.SafeDumper):
    def increase_indent(self, flow: bool = False, indentless: bool = False) -> None:
        return super().increase_indent(flow, False)

    def ignore_aliases(self, data: object) -> bool:
        return True


def _repr_none(dumper: yaml.SafeDumper, _: object):
    return dumper.represent_scalar("tag:yaml.org,2002:null", "")


_Dumper.add_representer(type(None), _repr_none)

def emit_outputs(blocks: list[dict[str, object]]) -> str:
    """All output blocks as one YAML sequence, byte-compatible with the
    historical emitter (see section comment for the three reinstated quirks)."""
    text = yaml.dump({"outputs": blocks}, Dumper=_Dumper, default_flow_style=False,
                     sort_keys=False, width=10**9)
    text = text.split("\n", 1)[1]  # drop the 'outputs:' wrapper line
    text = re.sub(r"(?m)^      run:\n(?!        - )", "      run:\n\n", text)
    text = re.sub(r'(?m)^(            - \$\{\{ compiler\("cxx"\) \}\})\n(        files:)',
                  r"\1\n\n\2", text)
    assert text.count("    tests: []\n") == 2, "metas are the only empty-tests blocks"


def pkg_head(pkg: PkgName, script: str, files: list[Claim] | None = None) -> dict[str, object]:
    """{'package': ..., 'inherit': ..., 'build': {...}} header of one block."""
    build: dict[str, object] = {"script": script}
    if files is not None:
        build["files"] = {"include": files}
    return {"package": {"name": pkg, "version": "${{ version }}"},
            "inherit": "build-cache", "build": build}


def script_test(name: str, extra_run: list[str]) -> dict[str, object]:
    """One CMake script test block (goes under the output's 'tests:')."""
    requirements: dict[str, object] = {"build": ['${{ compiler("cxx") }}']}
    if extra_run:
        requirements["run"] = extra_run
    return {"script": [f"bash tests/build_tests_cmake.sh {name}"],
            "requirements": requirements,
            "files": {"recipe": ["tests/build_tests_cmake.sh",
                                 "tests/CMakeLists.txt",
                                 f"tests/test_{name}.cpp"]}}


def cfg_call(base: str, kind: str, whole: list[str], deps: list[str]) -> str:
    """Build-script line: gen_cmake_configs.sh renders the config template at
    $PREFIX (single template for all 140 packages, no inline heredocs)."""
    args = " ".join([base, kind, *whole])
    if deps:
        args += " -- " + " ".join(deps)
    return f'bash "$RECIPE_DIR/gen_cmake_configs.sh" {args}'


def header_probe(claims: list[Claim], boost_dir: Path | None = None) -> str | None:
    """An include/-relative header path shipped by these claims (or None)."""
    for c in claims:
        rel = c.removeprefix("include/")
        if rel.endswith(HEADER_SUFFIXES):
            return rel
    if boost_dir is None:
        return None
    for c in claims:
        rel = c.removeprefix("include/boost/").removesuffix("/**")
        base = boost_dir / rel
        if c.endswith("/**") and base.is_dir():
            found = sorted(p for p in walk_files(base)
                           if p.suffix in HEADER_SUFFIXES)
            if found:
                return "boost/" + found[0].relative_to(boost_dir).as_posix()
    return None


def test_extra_reqs(tests_dir: Path, owner: dict[str, ModuleKey], key: ModuleKey,
                    test_base: str) -> list[PkgName]:
    """Test TUs may include headers of modules beyond the package's own
    shipped-header deps (e.g. test_array uses boost/functional/hash.hpp from
    boost-container_hash): scan the test file and return the owners of its
    includes."""
    f = tests_dir / f"test_{test_base}.cpp"
    if not f.is_file():
        return []
    pkg = pkg_of(key)
    extra: set[PkgName] = set()
    for target in iter_includes(f.read_text(errors="ignore")):
        dep = owner_of(owner, target)
        if dep is not None and pkg_of(dep) != pkg:
            extra.add(pkg_of(dep))
    return sorted(extra)


def main(argv: list[str] | None = None) -> int:
    args = list(argv if argv is not None else sys.argv[1:])
    if not args:
        print(__doc__)
        return 2
    root = Path(args[0])
    out_dir = Path(args[1]) if len(args) > 1 else OUT_DEFAULT
    skip = skip_from_build_sh()
    boost_dir = root / "boost"
    assert (root / "libs").is_dir() and boost_dir.is_dir(), f"bad boost root: {root}"
    out_dir.mkdir(parents=True, exist_ok=True)

    # ---------------- module universe ----------------
    modules, bd_deps, bd_buildable = load_boostdep()
    modset = set(modules)
    assert skip <= modset, f"skip list has non-modules: {sorted(skip - modset)}"
    # a module is compiled iff it has a src/ tree (b2 builds its archive from it)
    compiled = sorted({m for m in modset if (root / "libs" / m.replace("~", "/") / "src").is_dir()}
                      - skip)
    old = json.loads((out_dir / "deps.json").read_text())["_modules"]
    assert compiled == old, f"compiled roster drift: {set(compiled) ^ set(old)}"
    header_only = sorted(modset - set(compiled))
    tests_dir = HERE.parent / "tests"

    owner, files = build_ownership(root, modules)
    claims = {k: claims_for(files[k], boost_dir) for k in modules}

    link = {m: closure_order(bd_buildable, set(compiled), m) for m in compiled}
    # run deps: the vendored boostdep report, verbatim
    deps = {k: {d for d in bd_deps.get(k, set()) if d != k} for k in modules}

    # ---------------- data out ----------------
    data: dict[str, object] = {"_modules": compiled, "_header_only": header_only}
    for m in compiled:
        data[m] = {"direct": sorted(pkg_of(d) for d in deps[m]),
                   "compiled_direct": sorted(d for d in bd_buildable[m] if d in compiled),
                   "link_closure": link[m],
                   "files": claims[m]}
    for k in header_only:
        data[k] = {"deps": sorted(pkg_of(d) for d in deps[k]), "files": claims[k]}
    (out_dir / "deps.json").write_text(json.dumps(data, indent=2))

    edges: dict[ModuleKey, set[ModuleKey]] = {}
    for k in modules:
        edges[k] = set(deps[k])
    for m in compiled:
        edges[m] |= {d for d in bd_buildable[m] if d in compiled}
    order, broken = topo_order(modules, edges)

    # ---------------- YAML emission ----------------
    def compiled_block(m: ModuleKey) -> dict[str, object]:
        libs = LIB_FILES.get(m, [f"lib/libboost_{m}.a"])
        reqs = sorted({pkg_of(d) for d in deps[m] if (m, d) not in broken}
                      | {pkg_of(d) for d in bd_buildable[m] if d in compiled}
                      | set(EXTRA_RUN.get(m, [])))
        script = cfg_call(m, "compiled", [archive_of(m)],
                          [archive_of(d) for d in link[m] if d != m]
                          + EXTRA_ARCH.get(m, []))
        contents: dict[str, list[str]] = {"lib": [l.rsplit("/", 1)[-1] for l in libs]}
        probe = header_probe(claims[m])
        if probe:  # contents test probes the shipped headers too
            contents["include"] = [probe]
        extra = test_extra_reqs(tests_dir, owner, m, m)
        return {**pkg_head(f"boost-{m}", script, libs + claims[m] + [cfg_path(m)]),
                "requirements": {"run": reqs or None},
                "tests": [{"package_contents": contents}, script_test(m, extra)]}

    def ho_block(k: ModuleKey) -> dict[str, object]:
        pkg = pkg_of(k)
        base = pkg.removeprefix("boost-")
        reqs = sorted(pkg_of(d) for d in deps[k] if (k, d) not in broken)
        if (tests_dir / f"test_{base}.cpp").is_file():
            tests: list[dict[str, object]] = [
                script_test(base, test_extra_reqs(tests_dir, owner, k, base))]
        else:
            probe = header_probe(claims[k], boost_dir)
            assert probe, f"{pkg}: no probe header in claims {claims[k]}"
            tests = [{"package_contents": {"include": [probe]}}]
        return {**pkg_head(pkg, cfg_call(base, "header-only", [], []),
                           claims[k] + [cfg_path(base)]),
                "requirements": {"run": reqs or None},
                "tests": tests}

    def meta_block(name: PkgName, roster: list[PkgName]) -> dict[str, object]:
        return {**pkg_head(name, 'echo "Collecting files from cache"'),
                "requirements": {"run": roster},
                "tests": []}

    header = "# >>> generated by scripts/gen_boost_deps.py - do not edit by hand"
    footer = "# <<< generated"
    blocks = [compiled_block(k) if k in compiled else ho_block(k) for k in order] \
        + [meta_block("boost-headers", sorted(pkg_of(k) for k in header_only)),
           meta_block("boost-cpp", sorted(pkg_of(m) for m in modules))]
    generated = emit_outputs(blocks)
    (out_dir / "recipe_outputs.yaml").write_text(
        header + "\n" + generated + footer + "\n")

    recipe = (HERE.parent / "recipe.yaml").read_text()
    m = re.search(r"(?s)^# >>> generated.*?^# <<< generated", recipe, re.M)
    assert m is not None, "no generated markers in recipe.yaml - run the splice step"
    in_recipe = m.group(0)
    assert in_recipe == (header + "\n" + generated + footer), \
        "recipe.yaml generated region != recipe_outputs.yaml - run the splice step"
    assert "  - package:" not in recipe[m.end():], \
        "stray package block after the generated region in recipe.yaml"
    print(f"OK: {len(compiled)} compiled + {len(header_only)} header-only + 2 metas "
          f"(boost-headers, boost-cpp); generated region byte-identical in recipe.yaml")
    return 0


def closure_order(direct: dict[ModuleKey, set[ModuleKey]], compiled: set[ModuleKey],
                  mod: ModuleKey) -> list[ModuleKey]:
    """Post-order DFS: dependencies before dependents (valid static link order)."""
    out: list[ModuleKey] = []
    seen = {mod}

    def visit(m: ModuleKey) -> None:
        for d in sorted(direct.get(m, set())):
            if d in compiled and d not in seen:
                seen.add(d)
                visit(d)
                out.append(d)

    visit(mod)
    return out


if __name__ == "__main__":
    sys.exit(main())
