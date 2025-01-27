from pathlib import Path

from .. constants import RECIPES_EMSCRIPTEN_DIR
import json
import yaml
import os
import shutil
import json
import pprint

from collections import OrderedDict
from ruamel.yaml import YAML



def recipes_from_pyodie(pyodide_dir, conda_forge_noarch_repodata):



    # load repo as json
    
    print(f"Loading conda-forge noarch repodata from {conda_forge_noarch_repodata}")
    with open(conda_forge_noarch_repodata) as f:
        repodata = json.load(f)
    noarch_package_names = set()

    for key, value in repodata["packages"].items():
        noarch_package_names.add(value["name"].lower())
    
    print(f"Found {len(noarch_package_names)} noarch packages in conda-forge noarch repodata")


        


    # create a set of all recipes
    recipes = set()
    # iterate over all folders in RECIPES_EMSCRIPTEN_DIR
    for recipe_dir in RECIPES_EMSCRIPTEN_DIR.iterdir():
        if recipe_dir.is_dir():
            recipes.add(recipe_dir.name.lower())

    print(f"Found {len(recipes)} recipes in {RECIPES_EMSCRIPTEN_DIR}")

    pyodide_package_dir = Path(pyodide_dir) / "packages"
    # iterate over all folders in pyodide_package_dir

    candidte_recipes = []
    for package_dir in pyodide_package_dir.iterdir():
        if package_dir.is_dir():
            name = package_dir.name
            lower_name = name.lower()
            if lower_name in recipes:
                continue
            if lower_name in noarch_package_names:
                continue
            if name.startswith("_") or name.startswith(".") or name.startswith("pyodide"):
                continue
            if "test" in lower_name or "pyodide" in lower_name:
                continue
            if name.startswith("lib"):
                continue
            
            candidte_recipes.append((name, package_dir))

    # sort the candidate recipes
    candidte_recipes = sorted(candidte_recipes, key=lambda x: x[0])
    
    print(f"Found {len(candidte_recipes)} recipes in {pyodide_package_dir}")
    for name, package_dir in candidte_recipes:
        print(name)



def convert_pyodide_recipe(recipe_path, output_dir):
    output_dir = Path(output_dir)
    recipe_path = Path(recipe_path)

    # create output_dir if it does not exist
    output_dir.mkdir(exist_ok=True, parents=True)

    # read pyodide meta.yml as yaml
    meta_path = recipe_path / "meta.yaml"
    with open(meta_path) as f:
        meta = YAML().load(f)
    
    name = meta["package"]["name"]
    version = meta["package"]["version"]

    source = meta["source"]

    # replace hardcoded version with R"${{ version }}"
    source["url"] = source["url"].replace(version, R"${{ version }}")

    requirements = meta.get("requirements", {})
    run_reuirements = requirements.get("run", [])
    build_requirements = requirements.get("build", [])
    host_requirements = requirements.get("host", [])

    build_requirements.append(R"${{ compiler('cxx')}}")
    build_requirements.append("cross-python_emscripten-wasm32")
    build_requirements.append("python")

    host_requirements.append("python")


    

    about = meta.get("about", {})
    summary = about.get("summary", "")
    homepage = about.get("home", "")
    lic = about.get("license", "")


    # create recipe dir in output_dir
    output_recipe_dir = output_dir / name
    output_recipe_dir.mkdir(exist_ok=True)

    DictType = dict

    rattler_recipe = DictType()

    rattler_recipe["context"] = DictType()
    rattler_recipe["context"]["name"] = name
    rattler_recipe["context"]["version"] = version

    rattler_recipe["package"] = DictType()
    rattler_recipe["package"]["name"] = R"${{ name }}"
    rattler_recipe["package"]["version"] =  R"${{ version }}"

    rattler_recipe["source"] = DictType()
    rattler_recipe["source"]["url"] = source["url"]
    rattler_recipe["source"]["sha256"] = source["sha256"]

    rattler_recipe["build"] = DictType()
    rattler_recipe["build"]["number"] = 0

    rattler_recipe["requirements"] = DictType()
    rattler_recipe["requirements"]["build"] = build_requirements
    rattler_recipe["requirements"]["host"] = host_requirements

    
    if len(run_reuirements) > 0:
        rattler_recipe["requirements"]["run"] = run_reuirements

    
    pytester_script = DictType()
    pytester_script["script"] = "pytester"
    pytester_script["requirements"] = DictType()
    pytester_script["requirements"]["build"] = ["pytester"]
    pytester_script["requirements"]["run"] = ["pytester-run"]
    pytester_script["files"] = DictType()
    pytester_script["files"]["recipe"] = [
        f"test_{name}.py"
    ]

    # create testing scarefold
    rattler_recipe["tests"] = [pytester_script]

    # create about section
    rattler_recipe["about"] = DictType()
    rattler_recipe["about"]["summary"] = summary
    rattler_recipe["about"]["homepage"] = homepage
    rattler_recipe["about"]["license"] = lic


    # write rattler recipe to output_recipe_dir
    with open(output_recipe_dir / "recipe.yaml", "w") as f:
        YAML().dump(rattler_recipe, f)

    # create test_{name}.py

    test_file = output_recipe_dir / f"test_{name}.py"



    try:
        import_names = meta["package"]["top-level"]
    except KeyError:
        import_names = [name]
    
    
    with open(test_file, "w") as f:
        f.write(f"def test_import():\n")
        for import_name in import_names:
            f.write(f"    import {import_name}\n")


    # build script
    build_script = output_recipe_dir / "build.sh"
    with open(build_script, "w") as f:
        f.write("#!/bin/bash\n\n")
        f.write("set -e\n\n")
        f.write("$PYTHON -m pip install . --no-deps --ignore-installed -vv\n")
    


    
    
    pprint.pprint(meta)