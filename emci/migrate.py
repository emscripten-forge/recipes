
import contextlib
import shutil
import tempfile
import os

from .rattler_build import build_with_rattler, BuildTimeoutError
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
from hashlib import sha256
import fnmatch
import shutil
import sys
from ruamel.yaml import YAML
from .constants import RECIPES_EMSCRIPTEN_DIR, TO_MIGRATE_RECIPES_EMSCRIPTEN_DIR
import contextlib
from collections import defaultdict
from pprint import pprint
import json
import hashlib
import networkx as nx
from .git_utils import (
    bot_github_user_ctx, 
    git_branch_ctx, 
    make_pr_for_recipe, 
    automerge_is_enabled,
    set_bot_user,
    get_current_branch_name
)
import logging
import tarfile


# globals
ON_GITHUB_ACTIONS = os.environ.get('GITHUB_ACTIONS') == 'true'
logger = logging.getLogger(__name__)
yaml = YAML()
yaml.width = 120

# helper to generalize multioutput / single-output recipes
def iter_outputs(recipe, include_staging_outputs=True):
    is_multi_output = "outputs" in recipe
    if is_multi_output:
        for output in recipe["outputs"]:
            if not include_staging_outputs and "staging" in output:
                continue
            yield output
    else:
        yield recipe

# helper to iterate over various requirements sections
def iter_requirements(output):
    if "requirements" in output:
        yield output["requirements"]
    
    if "test" in output and "requirements" in output["test"]:
        yield output["test"]["requirements"]

# more read-friendly helper functions
def replace_in_list(lst, old, new):
    return [new if x == old else x for x in lst]


# migrate a **single** recipe.yaml
def migrate_recipe_yaml(recipe):

    # reset build number
    if "build" in recipe:
        recipe["build"]["number"] = 0
    

    # replace "python" with "python-dev" in host requirements
    for output in iter_outputs(recipe, include_staging_outputs=True):
        for req in iter_requirements(output):
           if 'host' in req:
                req['host'] = replace_in_list(req['host'], "python", "python-dev")


    # add generic testing block to each output's tests section
    for output in iter_outputs(recipe, include_staging_outputs=False):
        if "tests" not in output:
            output["tests"] = []
        output["tests"].append({
            "script": "generic-testing",
            "requirements": {
                "build": ["generic-testing"]
            }
        })
    
    return recipe


# migrate a **single** recipe
def migrate_recipe(recipe_dir, output_dir):
    recipe_dir = Path(recipe_dir)
    output_dir = Path(output_dir)

    if not output_dir.exists():
        output_dir.mkdir(parents=True)
    dest_dir = output_dir / recipe_dir.name
    if not dest_dir.exists():
        shutil.copytree(recipe_dir, dest_dir)

    # read the file
    recipe_file = dest_dir / "recipe.yaml"
    with open(recipe_file) as file:
        recipe = yaml.load(file)

    recipe = migrate_recipe_yaml(recipe)
    
    # write the modified recipe back to the file
    with open(recipe_file, "w") as file:
        yaml.dump(recipe, file)

@contextlib.contextmanager
def extract_pkg(pkg_path):
    with TemporaryDirectory() as temp_dir:
        with tarfile.open(pkg_path, mode="r:*") as tar:
            tar.extractall(temp_dir)
        yield Path(temp_dir)




def build_with_rattler_wrapper(*args, **kwargs):
    try:
        ret = build_with_rattler(*args, **kwargs,  format='tar-bz2', log_style='simple', continue_on_failure=True)
        return ret
    except BuildTimeoutError:
        print("Build timed out, continuing with other recipes...")




def get_github_user_ctx(use_bot):
    
    @contextlib.contextmanager
    def empty_context_manager():
        yield

    if ON_GITHUB_ACTIONS:
        # We are on GitHub Actions, we **cannot** **restore** the user account
        # therefore we just set the bot user and use an empty context manager
        set_bot_user()
        user_ctx = empty_context_manager
    else:
        if use_bot:
            user_ctx = bot_github_user_ctx
        else:
            user_ctx = empty_context_manager
    return user_ctx



def pkg_list_to_branch_name(pkg_list, max_branch_name_length=100):
    # get short hash 
    data = "\0".join(sorted(pkg_list)).encode("utf-8")
    hash =  hashlib.sha256(data).hexdigest()[:12]

    name =  f"migrate_6x_{hash}_" + "_".join(pkg_list)
    if len(name) > max_branch_name_length:
        name = name[:max_branch_name_length]
    return name

PR_TITLE_PREFIX = "[6x-Migration]"

def pkg_list_to_pr_title(pkg_list, max_title_length=100):
    title = PR_TITLE_PREFIX + " " + ", ".join(pkg_list)
    if len(title) > max_title_length:
        title = title[:max_title_length]
    return title

def generate_pr_body(successful_builds):
    return "Migrated recipes:\n" + "\n".join(
        f"- {recipe}" for recipe in successful_builds
    )
def pr_body_to_pkg_list(pr_body):
    lines = pr_body.splitlines()
    return [line[2:] for line in lines if line.startswith("- ")]



def get_list_of_already_migrating_recipes():
    command = [
            "gh", "pr", "list",
            # "--author", "emscripten-forge-bot",
            "--base", "emscripten-6x",
            "--json", "number,title,body",
            "--limit", "200" # default is only 30
        ]
    result = subprocess.check_output(command).decode()
    result = json.loads(result)
    already_migrating = []
    for pr in result:
        title = pr.get("title", "")
        if title.startswith(PR_TITLE_PREFIX):
            body = pr.get("body", "")
            already_migrating.extend(pr_body_to_pkg_list(body))
    return set(already_migrating)



def iterate_pkg_files(path):
    path = Path(path)
    if not path.exists():
        return
    for pkg_file in path.iterdir():
        if pkg_file.is_file() and str(pkg_file).endswith(".tar.bz2"):
            yield pkg_file


def spec_to_name(spec):
    # spec is smth like emscripten-abi ==6.0.8
    return spec.split()[0]

def cluster_recipes(filtered_to_migrate_dir, output_dir, target_platform, pkg_to_recipe_dir):

    recipe_info = defaultdict( lambda: {
        "provides": set(),
        "needs": set()
    })

    # mapping from pkg-name to recipe name
    # ie from 'libzlib' to 'zlib'
    # since 'libzlib' is the name of an output from the
    # recipe in the 'zlib' directory
    pkg_to_providing_recipe_name = {}

    logger.info("Clustering recipes ")
    target_output_dir = output_dir / target_platform
    for pkg_file in iterate_pkg_files(target_output_dir):

        logger.info(f"Processing package file: {pkg_file}")
        with extract_pkg(pkg_file) as extract_pkg_dir:
            recipe_yaml = (Path(extract_pkg_dir) / "info" / "recipe"/"recipe.yaml").read_text()
            recipe_hash = sha256(recipe_yaml.encode("utf-8")).hexdigest()
            if recipe_hash not in pkg_to_recipe_dir:
                logger.warning(f"Recipe hash {recipe_hash} not found in pkg_to_recipe_dir")
                continue

            # load the rendered recipe
            rendered_recipe_yaml = (Path(extract_pkg_dir) / "info" / "recipe" / "rendered_recipe.yaml")
            with open(rendered_recipe_yaml, "r") as f:
                rendered_recipe = yaml.load(f)    

            # recipe name is the dirname in the recipes folder
            recipe_name = pkg_to_recipe_dir[recipe_hash]
            info = recipe_info[recipe_name] 

            pkg_name = rendered_recipe['recipe']['package']['name']
            info["provides"].add(pkg_name)
            pkg_to_providing_recipe_name[pkg_name] = recipe_name
            
            # extract all the pkgs that this recipe needs
            # (since we do not resolve run, this is a approximation)
            finalized_dependencies = rendered_recipe["finalized_dependencies"]
            host = finalized_dependencies.get("host", [])
            assert host is not None
            assert 'resolved' in host
            for dep in host['resolved']:
                assert 'name' in dep
                info["needs"].add(dep['name'])
               

            run = finalized_dependencies.get("run", [])
            assert run is not None
            assert 'depends' in run
            for dep in run['depends']:
                if 'spec' in dep:
                    spec = dep['spec']
                    info["needs"].add(spec_to_name(spec))
                # not at all sure about this
                # python is in soucce for bitarray
                # 
                # depends:
                # - source: python
                # - spec: emscripten-abi >=6,<7.0a0
                #   from: build
                #   run_export: cross-python_emscripten-wasm32
                # - spec: emscripten-abi ==6.0.8
                #   from: build
                #   run_export: emscripten_emscripten-wasm32
                if 'source' in dep:
                    source = dep['source']
                    info["needs"].add(spec_to_name(source))

    
    print("-----\nrecipe_info")
    pprint(recipe_info, indent=2)
    print("-----\npkg_to_providing_recipe_name")
    pprint(pkg_to_providing_recipe_name, indent=2)
    recipe_recipe_deps = dict()
    for recipe_name, info in recipe_info.items():
        recipe_recipe_deps[recipe_name] = set()
        for need in info["needs"]:
            if need in pkg_to_providing_recipe_name:
                providing_recipe = pkg_to_providing_recipe_name[need]
                recipe_recipe_deps[recipe_name].add(providing_recipe)

    print("-----\nrecipe_recipe_deps")
    pprint(recipe_recipe_deps, indent=2)

    # create undirect graph  to cluster recipes based on dependencies
    G = nx.Graph()
    for recipe, deps in recipe_recipe_deps.items():
        G.add_node(recipe)
        for dep in deps:
            G.add_edge(recipe, dep)

    clusters = list(nx.connected_components(G))
    print("-----\nclusters")
    pprint(clusters, indent=2)
    return clusters



def post_tentative_build( filtered_to_migrate_dir, output_dir, target_platform, pkg_to_recipe_dir):
    # check which recipes were successfully built

    # cluster recipes 
    clusters = cluster_recipes(filtered_to_migrate_dir, output_dir, target_platform, pkg_to_recipe_dir)
    if len(clusters) == 0:
        logger.warning("No clusters found")
        return

    for cluster in clusters:
        successful_builds = list(cluster)

        try:
            branch_name = pkg_list_to_branch_name(successful_builds)
            with git_branch_ctx(branch_name, stash_current=False):



                # move build recipes from filtered_to_migrate_dir
                # to the actual recipe dir RECIPES_EMSCRIPTEN_DIR
                # copy filtered_to_migrate_dir/<RECIPE> to RECIPES_EMSCRIPTEN_DIR/<RECIPE> 
                for recipe_dir in successful_builds:

                    # this is the recipe where we already applied some transformations
                    # (ie python in host ist renamed to python-dev, and similar changes)
                    src_dir_modified = filtered_to_migrate_dir / recipe_dir

                    # where the original recipe is located
                    src_dir_original = TO_MIGRATE_RECIPES_EMSCRIPTEN_DIR / recipe_dir

                    dst_dir = RECIPES_EMSCRIPTEN_DIR / recipe_dir

                    
                    if  dst_dir.exists():
                        logger.warning(f"Destination directory {dst_dir} already exists")

                    
                    shutil.copytree(src_dir_modified, dst_dir)

                    # delete the old file via git
                    subprocess.run(["git", "rm", "-r", str(src_dir_original)], check=True)
                    subprocess.run(["git", "add", str(dst_dir)], check=True)
                    subprocess.run(["git", "commit", "-m", f"Migrate recipe {recipe_dir}"], check=True)

                # push the changes to the remote(with force if necessary)
                subprocess.run(["git", "push", "--force", "origin", branch_name], check=True)


                pr_title = pkg_list_to_pr_title(successful_builds)

                pr_body = generate_pr_body(successful_builds)

                # get current user
                if ON_GITHUB_ACTIONS:
                    head = branch_name
                else:
                    current_user = subprocess.check_output(['git', 'config', 'user.name']).decode().strip()
                    head = f"{current_user}:{branch_name}"

                args = ['gh', 'pr', 'create',
                        "--repo", "emscripten-forge/recipes",
                        '--base', "emscripten-6x",
                        "--head", head,
                        '--title', pr_title, '--body', pr_body,
                        '--label', '6x'
                ]

                # call gh to create a PR
                subprocess.check_call(args, cwd=os.getcwd())
        except Exception as e:
            logger.error(f"Failed to create PR: {e}, continuing with the next one")




def build_pkg_to_recipe_dir(to_migrate_dir):
    pkg_to_recipe_dir = {}
    for recipe_dir in to_migrate_dir.iterdir():
        if recipe_dir.is_dir() and (recipe_dir / "recipe.yaml").exists():
            # load the recipe.yaml content
            recipe_content = (recipe_dir / "recipe.yaml").read_text()
            recipe_hash = sha256(recipe_content.encode("utf-8")).hexdigest()
            pkg_to_recipe_dir[recipe_hash] = recipe_dir.name
    return pkg_to_recipe_dir


def copy_selected_recipes(to_migrate_dir, already_migrating,  wildcards, wildcards_ignore, recipe_transformations, output_dir):
    to_migrate_dir = Path(to_migrate_dir)
    output_dir = Path(output_dir)

    if not output_dir.exists():
        output_dir.mkdir(parents=True)

    logger.info(f"wildcards to ignore: {wildcards_ignore}")
    logger.info(f"wildcards to include: {wildcards}")
    for recipe_dir in to_migrate_dir.iterdir():
        if recipe_dir.is_dir() and (recipe_dir / "recipe.yaml").exists():
            # dir_name
            dir_name = recipe_dir.name
            if wildcards is None or any(fnmatch.fnmatch(dir_name, wc) for wc in wildcards):

                if wildcards_ignore is not None and any(fnmatch.fnmatch(dir_name, wc) for wc in wildcards_ignore):
                    continue

                if dir_name in already_migrating:
                    continue

                migrate_recipe(recipe_dir, output_dir)



    
def build_tentative(output_dir=None,
                    target_platform='emscripten-wasm32', 
                    timeout=None, 
                    wildcards=None,
                    wildcards_ignore=None):
    """
    entry point for tentative building
    """

    if wildcards is None:
        wildcards = ['*']
    if wildcards_ignore is None:
        wildcards_ignore = []




    # create temp dir
    with TemporaryDirectory() as temp_dir:
        temp_dir = Path(temp_dir)
        if output_dir is None:
            output_dir = temp_dir / "outdir"
        output_dir.mkdir(parents=True, exist_ok=True)

        filtered_to_migrate_dir = temp_dir / "filtered_to_migrate"
        filtered_to_migrate_dir.mkdir(parents=True)
        
        already_migrating = get_list_of_already_migrating_recipes()
        logger.info(f"Already migrating recipes: {already_migrating}")
        copy_selected_recipes(TO_MIGRATE_RECIPES_EMSCRIPTEN_DIR, already_migrating, wildcards, wildcards_ignore, recipe_transformations=[], output_dir=filtered_to_migrate_dir)


        # map recipe.yaml content to directory name 
        # st. we can later map the successful builds 
        # back to their respective recipe dir
        pkg_to_recipe_dir = build_pkg_to_recipe_dir(filtered_to_migrate_dir)

        # build all pkgs
        if 1:
            build_with_rattler_wrapper(recipes_dir=filtered_to_migrate_dir, output_dir=output_dir, 
                            target_platform=target_platform, skip_existing="local", 
                        timeout=timeout)

        if 1:
            subprocess.check_call(['gh', 'repo', 'set-default', 'emscripten-forge/recipes'], cwd=os.getcwd())

            pr_target_branch = "emscripten-6x"
            with get_github_user_ctx(use_bot=False)():

                # we want to make th changes ontop of pr_target_branch
                # but after the script we want to switch back to whatever branch we were on before
                with git_branch_ctx(pr_target_branch, stash_current=False, auto_delete=False, new_branch=False):


                    # force reset the branch to match the upstream state
                    cmd = "git fetch https://github.com/emscripten-forge/recipes.git emscripten-6x && git reset --hard FETCH_HEAD"
                    subprocess.check_call(cmd, shell=True)


                    # after the build, process the results
                    post_tentative_build(filtered_to_migrate_dir=filtered_to_migrate_dir,
                                        output_dir=output_dir, 
                                        target_platform=target_platform, 
                                        pkg_to_recipe_dir=pkg_to_recipe_dir)

            
