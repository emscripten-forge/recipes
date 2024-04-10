import boa.core.monkeypatch # noqa
from boa.core.run_build import run_build
from boa.pyapi import py_build
from .testing.package_testing import test_package as test_package_impl


import os
import shutil
import glob
import functools

from contextlib import contextmanager

from ..constants import CONDA_BLD_DIR

@contextmanager
def restore_cwd():
    base_work_dir = os.getcwd()
    yield
    os.chdir(base_work_dir)


def test_package(recipe, work_dir):
    # recipe_dir = os.path.join(recipes_dir, recipe_name)
    print(f"Test recipe: {recipe} in work_dir: {work_dir}")
    test_package_impl(recipe=recipe, work_dir=work_dir, conda_bld_dir=CONDA_BLD_DIR)



def cleanup():
    do_not_delete = ["noarch", "linux-64", "emscripten-wasm32", "icons"]
    do_not_delete = [os.path.join(CONDA_BLD_DIR, d) for d in do_not_delete]

    for dirname in glob.iglob(os.path.join(CONDA_BLD_DIR, "**"), recursive=False):
        if os.path.isdir(dirname):
            if dirname not in do_not_delete and "_" in dirname:
                shutil.rmtree(dirname)


def post_build_callback(
    recipe, target_platform, sorted_outputs, final_names, skip_tests, work_dir
):
    if target_platform == "emscripten-wasm32" and (not skip_tests):
        with restore_cwd():
            test_package(recipe=recipe, work_dir=work_dir)
    cleanup()


def build_package_with_boa(
    work_dir,
    platform,
    target=None,
    recipe_dir=None,
    skip_tests=False,
    skip_existing=False,
):





    target_platform = None
    if platform:
        target_platform = platform
    str_skip_existing = "default"
    if skip_existing:
        str_skip_existing = "yes"

    cb = functools.partial(
        post_build_callback, skip_tests=skip_tests, work_dir=work_dir
    )

    py_build(
        target=target,
        recipe_dir=recipe_dir,
        target_platform=target_platform,
        skip_existing=str_skip_existing,
        post_build_callback=cb,
    )
    os.chdir(work_dir)

