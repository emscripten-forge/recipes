#!/usr/bin/env python

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

import contextlib
import glob
import os
import os.path
from pathlib import Path

from os.path import join as pjoin
import re
import shlex
import shutil
import sys

if sys.version_info >= (3, 10):
    import sysconfig
else:
    # Get correct EXT_SUFFIX on Windows (https://bugs.python.org/issue39825)
    from distutils import sysconfig

import pkg_resources
from setuptools import setup, Extension, Distribution, find_namespace_packages

from Cython.Distutils import build_ext as _build_ext
import Cython

# Check if we're running 64-bit Python
is_64_bit = sys.maxsize > 2**32

if Cython.__version__ < "0.29.22":
    raise Exception("Please upgrade to Cython 0.29.22 or newer")

setup_dir = os.path.abspath(os.path.dirname(__file__))

recipe_dir = os.environ["RECIPE_DIR"]
ext_suffix = sysconfig.get_config_var("EXT_SUFFIX")
ext_suffix = ".so"

env_prefix = os.environ["PREFIX"]

build_env_prefix = os.environ["BUILD_PREFIX"]


@contextlib.contextmanager
def changed_dir(dirname):
    oldcwd = os.getcwd()
    os.chdir(dirname)
    try:
        yield
    finally:
        os.chdir(oldcwd)


def strtobool(val):
    """Convert a string representation of truth to true (1) or false (0).

    True values are 'y', 'yes', 't', 'true', 'on', and '1'; false values
    are 'n', 'no', 'f', 'false', 'off', and '0'.  Raises ValueError if
    'val' is anything else.
    """
    # Copied from distutils
    val = val.lower()
    if val in ("y", "yes", "t", "true", "on", "1"):
        return 1
    elif val in ("n", "no", "f", "false", "off", "0"):
        return 0
    else:
        raise ValueError("invalid truth value %r" % (val,))


class build_ext(_build_ext):
    _found_names = ()

    def build_extensions(self):
        numpy_incl = pkg_resources.resource_filename("numpy", "core/include")

        self.extensions = [ext for ext in self.extensions if ext.name != "__dummy__"]

        for ext in self.extensions:
            if hasattr(ext, "include_dirs") and numpy_incl not in ext.include_dirs:
                ext.include_dirs.append(numpy_incl)
        _build_ext.build_extensions(self)

    def run(self):
        self._run_cmake_pyarrow_cpp()
        self._run_cmake()
        _build_ext.run(self)

    # adapted from cmake_build_ext in dynd-python
    # github.com/libdynd/dynd-python

    description = "Build the C-extensions for arrow"
    user_options = [
        ("cmake-generator=", None, "CMake generator"),
        ("extra-cmake-args=", None, "extra arguments for CMake"),
        ("build-type=", None, "build type (debug or release), default release"),
        ("boost-namespace=", None, "namespace of boost (default: boost)"),
        ("with-cuda", None, "build the Cuda extension"),
        ("with-flight", None, "build the Flight extension"),
        ("with-substrait", None, "build the Substrait extension"),
        ("with-dataset", None, "build the Dataset extension"),
        ("with-parquet", None, "build the Parquet extension"),
        ("with-parquet-encryption", None, "build the Parquet encryption extension"),
        ("with-gcs", None, "build the Google Cloud Storage (GCS) extension"),
        ("with-s3", None, "build the Amazon S3 extension"),
        ("with-static-parquet", None, "link parquet statically"),
        ("with-static-boost", None, "link boost statically"),
        ("with-plasma", None, "build the Plasma extension"),
        ("with-tensorflow", None, "build pyarrow with TensorFlow support"),
        ("with-orc", None, "build the ORC extension"),
        ("with-gandiva", None, "build the Gandiva extension"),
        ("generate-coverage", None, "enable Cython code coverage"),
        ("bundle-boost", None, "bundle the (shared) Boost libraries"),
        (
            "bundle-cython-cpp",
            None,
            "bundle generated Cython C++ code " "(used for code coverage)",
        ),
        ("bundle-arrow-cpp", None, "bundle the Arrow C++ libraries"),
        ("bundle-arrow-cpp-headers", None, "bundle the Arrow C++ headers"),
        ("bundle-plasma-executable", None, "bundle the plasma-store-server executable"),
    ] + _build_ext.user_options

    def initialize_options(self):
        _build_ext.initialize_options(self)
        self.cmake_generator = os.environ.get("PYARROW_CMAKE_GENERATOR")
        if not self.cmake_generator and sys.platform == "win32":
            self.cmake_generator = "Visual Studio 15 2017 Win64"
        self.extra_cmake_args = os.environ.get("PYARROW_CMAKE_OPTIONS", "")
        self.build_type = os.environ.get("PYARROW_BUILD_TYPE", "release").lower()
        self.boost_namespace = os.environ.get("PYARROW_BOOST_NAMESPACE", "boost")

        self.cmake_cxxflags = os.environ.get("PYARROW_CXXFLAGS", "")

        if sys.platform == "win32":
            # Cannot do debug builds in Windows unless Python itself is a debug
            # build
            if not hasattr(sys, "gettotalrefcount"):
                self.build_type = "release"

        self.with_gcs = strtobool(os.environ.get("PYARROW_WITH_GCS", "0"))
        self.with_s3 = strtobool(os.environ.get("PYARROW_WITH_S3", "0"))
        self.with_hdfs = strtobool(os.environ.get("PYARROW_WITH_HDFS", "0"))
        self.with_cuda = strtobool(os.environ.get("PYARROW_WITH_CUDA", "0"))
        self.with_substrait = strtobool(os.environ.get("PYARROW_WITH_SUBSTRAIT", "0"))
        self.with_flight = strtobool(os.environ.get("PYARROW_WITH_FLIGHT", "0"))
        self.with_dataset = strtobool(os.environ.get("PYARROW_WITH_DATASET", "0"))
        self.with_parquet = strtobool(os.environ.get("PYARROW_WITH_PARQUET", "0"))
        self.with_static_parquet = strtobool(
            os.environ.get("PYARROW_WITH_STATIC_PARQUET", "0")
        )
        self.with_parquet_encryption = strtobool(
            os.environ.get("PYARROW_WITH_PARQUET_ENCRYPTION", "0")
        )
        self.with_static_boost = strtobool(
            os.environ.get("PYARROW_WITH_STATIC_BOOST", "0")
        )
        self.with_plasma = strtobool(os.environ.get("PYARROW_WITH_PLASMA", "0"))
        self.with_tensorflow = strtobool(os.environ.get("PYARROW_WITH_TENSORFLOW", "0"))
        self.with_orc = strtobool(os.environ.get("PYARROW_WITH_ORC", "0"))
        self.with_gandiva = strtobool(os.environ.get("PYARROW_WITH_GANDIVA", "0"))
        self.generate_coverage = strtobool(
            os.environ.get("PYARROW_GENERATE_COVERAGE", "0")
        )
        self.bundle_arrow_cpp = strtobool(
            os.environ.get("PYARROW_BUNDLE_ARROW_CPP", "0")
        )
        self.bundle_cython_cpp = strtobool(
            os.environ.get("PYARROW_BUNDLE_CYTHON_CPP", "0")
        )
        self.bundle_boost = strtobool(os.environ.get("PYARROW_BUNDLE_BOOST", "0"))
        self.bundle_arrow_cpp_headers = strtobool(
            os.environ.get("PYARROW_BUNDLE_ARROW_CPP_HEADERS", "1")
        )
        self.bundle_plasma_executable = strtobool(
            os.environ.get("PYARROW_BUNDLE_PLASMA_EXECUTABLE", "1")
        )

        self.with_parquet_encryption = (
            self.with_parquet_encryption and self.with_parquet
        )

    CYTHON_MODULE_NAMES = [
        "lib",
        "_fs",
        "_csv",
        "_json",
        "_compute",
        "_cuda",
        "_flight",
        "_dataset",
        "_dataset_orc",
        "_dataset_parquet",
        "_exec_plan",
        "_feather",
        "_parquet",
        "_parquet_encryption",
        "_pyarrow_cpp_tests",
        "_orc",
        "_plasma",
        "_gcsfs",
        "_s3fs",
        "_substrait",
        "_hdfs",
        "_hdfsio",
        "gandiva",
    ]

    def _run_cmake_pyarrow_cpp(self):
        # check if build_type is correctly passed / set
        if self.build_type.lower() not in ("release", "debug", "relwithdebinfo"):
            raise ValueError(
                "--build-type (or PYARROW_BUILD_TYPE) needs to "
                "be 'release', 'debug' or 'relwithdebinfo'"
            )

        # The directory containing this setup.py
        source = os.path.dirname(os.path.abspath(__file__))
        # The directory containing this PyArrow C++ CMakeLists.txt
        source_pyarrow_cpp = pjoin(source, "pyarrow/src")

        # The directory for the module being built
        build_dir = pjoin(os.getcwd(), "build", "cpp")

        if not os.path.isdir(build_dir):
            self.mkpath(build_dir)

        # Change to the build directory
        with changed_dir(build_dir):
            # cmake args
            cmake_options = [
                "-DCMAKE_BUILD_TYPE=" + str(self.build_type.lower()),
                "-DCMAKE_INSTALL_LIBDIR=lib",
                "-DCMAKE_INSTALL_PREFIX=" + env_prefix,
                "-DPYARROW_CXXFLAGS=" + str(self.cmake_cxxflags),
                "-DArrow_DIR=" + pjoin(env_prefix, "lib", "cmake", "Arrow"),
                f"-Dre2_DIR={env_prefix}/lib/cmake/re2",
                f"-Dutf8proc_LIB={env_prefix}/lib/libutf8proc.a",
                f"-Dutf8proc_INCLUDE_DIR={env_prefix}/include",
                f"-DCMAKE_PREFIX_PATH:PATH={env_prefix}",
                f"-DCMAKE_INSTALL_PREFIX:PATH={env_prefix}",
                "-DCMAKE_INSTALL_LIBDIR=lib",
                "-DCMAKE_BUILD_TYPE=Release",
                "-DARROW_SIMD_LEVEL=NONE",
                "-DARROW_RUNTIME_SIMD_LEVEL=NONE",
                "-DARROW_BUILD_TESTS=OFF",
                "-DARROW_ENABLE_TIMING_TESTS=OFF",
                "-DARROW_BUILD_SHARED=ON",
                "-DARROW_COMPUTE=ON",
                f"-DCMAKE_PROJECT_INCLUDE={recipe_dir}/overwriteProp.cmake",
                "-DARROW_CPU_FLAG=emscripten32",
            ]

            # Check for specific options
            def append_cmake_bool(value, varname):
                cmake_options.append(
                    "-D{0}={1}".format(varname, "on" if value else "off")
                )

            append_cmake_bool(self.with_dataset, "PYARROW_WITH_DATASET")
            append_cmake_bool(
                self.with_parquet_encryption, "PYARROW_WITH_PARQUET_ENCRYPTION"
            )
            append_cmake_bool(self.with_hdfs, "PYARROW_WITH_HDFS")

            # Windows
            if self.cmake_generator:
                cmake_options += ["-G", self.cmake_generator]

            # build args
            build_tool_args = []
            if os.environ.get("PYARROW_BUILD_VERBOSE", "0") == "1":
                cmake_options.append("-DCMAKE_VERBOSE_MAKEFILE=ON")
            PYARROW_PARALLEL = 8
            build_tool_args.append("--")
            build_tool_args.append("-j{0}".format(PYARROW_PARALLEL))

            # run cmake
            print("-- Running CMake for PyArrow C++")
            self.spawn(["emcmake", "cmake"] + cmake_options + [source_pyarrow_cpp])
            print("-- Finished CMake for PyArrow C++")
            # run make & install
            print("-- Running CMake build and install for PyArrow C++")
            self.spawn(
                [
                    "cmake",
                    "--build",
                    ".",
                    "--config",
                    self.build_type,
                    "--target",
                    "install",
                ]
                + build_tool_args
            )
            print("-- Finished CMake build and install for PyArrow C++")

    def _run_cmake(self):
        print("PART 2\n\n")

        # arrow_dir = f"{env_prefix}/lib/cmake/ArrowPython/"
        # print(*Path(arrow_dir).iterdir(), sep="\n")

        # check if build_type is correctly passed / set
        if self.build_type.lower() not in ("release", "debug", "relwithdebinfo"):
            raise ValueError(
                "--build-type (or PYARROW_BUILD_TYPE) needs to "
                "be 'release', 'debug' or 'relwithdebinfo'"
            )

        # The directory containing this setup.py
        source = os.path.dirname(os.path.abspath(__file__))

        # The staging directory for the module being built
        build_cmd = self.get_finalized_command("build")
        saved_cwd = os.getcwd()
        build_temp = pjoin(saved_cwd, build_cmd.build_temp)
        build_lib = pjoin(saved_cwd, build_cmd.build_lib)

        if not os.path.isdir(build_temp):
            self.mkpath(build_temp)

        if self.inplace:
            # a bit hacky
            build_lib = saved_cwd

        # Change to the build directory
        with changed_dir(build_temp):
            # Detect if we built elsewhere
            if os.path.isfile("CMakeCache.txt"):
                cachefile = open("CMakeCache.txt", "r")
                cachedir = re.search(
                    "CMAKE_CACHEFILE_DIR:INTERNAL=(.*)", cachefile.read()
                ).group(1)
                cachefile.close()
                if cachedir != build_temp:
                    build_base = pjoin(saved_cwd, build_cmd.build_base)
                    print(
                        f"-- Skipping build. Temp build {build_temp} does "
                        f"not match cached dir {cachedir}"
                    )
                    print(
                        "---- For a clean build you might want to delete "
                        f"{build_base}."
                    )
                    return

            static_lib_option = ""

            cmake_options = [
                "-DCMAKE_INSTALL_PREFIX=" + env_prefix,
                "-DPYARROW_CPP_HOME=" + env_prefix,
                "-DPYARROW_CXXFLAGS=" + str(self.cmake_cxxflags),
                f"-DArrow_DIR={env_prefix}/lib/cmake/Arrow/",
                f"-DArrowPython_DIR={env_prefix}/lib/cmake/ArrowPython/",
                f"-Dre2_DIR={env_prefix}/lib/cmake/re2",
                f"-Dutf8proc_LIB={env_prefix}/lib/libutf8proc.a",
                f"-Dutf8proc_INCLUDE_DIR={env_prefix}/include",
                f"-DCMAKE_PROJECT_INCLUDE={recipe_dir}/overwriteProp.cmake",
            ]

            def append_cmake_bool(value, varname):
                cmake_options.append(
                    "-D{0}={1}".format(varname, "on" if value else "off")
                )

            if self.cmake_generator:
                cmake_options += ["-G", self.cmake_generator]

            append_cmake_bool(False, "PYARROW_BUILD_CUDA")
            append_cmake_bool(False, "PYARROW_BUILD_SUBSTRAIT")
            append_cmake_bool(False, "PYARROW_BUILD_FLIGHT")
            append_cmake_bool(False, "PYARROW_BUILD_GANDIVA")
            append_cmake_bool(False, "PYARROW_BUILD_DATASET")
            append_cmake_bool(False, "PYARROW_BUILD_ORC")
            append_cmake_bool(False, "PYARROW_BUILD_PARQUET")
            append_cmake_bool(False, "PYARROW_BUILD_PARQUET_ENCRYPTION")
            append_cmake_bool(False, "PYARROW_BUILD_PLASMA")
            append_cmake_bool(False, "PYARROW_BUILD_GCS")
            append_cmake_bool(False, "PYARROW_BUILD_S3")
            append_cmake_bool(False, "PYARROW_BUILD_HDFS")
            append_cmake_bool(False, "PYARROW_USE_TENSORFLOW")
            append_cmake_bool(False, "PYARROW_BUNDLE_ARROW_CPP")
            append_cmake_bool(False, "PYARROW_BUNDLE_BOOST")
            append_cmake_bool(False, "PYARROW_GENERATE_COVERAGE")
            append_cmake_bool(False, "PYARROW_BOOST_USE_SHARED")
            append_cmake_bool(False, "PYARROW_PARQUET_USE_SHARED")

            cmake_options.append(
                "-DCMAKE_BUILD_TYPE={0}".format(self.build_type.lower())
            )

            if self.boost_namespace != "boost":
                cmake_options.append(
                    "-DBoost_NAMESPACE={}".format(self.boost_namespace)
                )

            extra_cmake_args = shlex.split(self.extra_cmake_args)

            build_tool_args = []
            if sys.platform == "win32":
                if not is_64_bit:
                    raise RuntimeError("Not supported on 32-bit Windows")
            else:

                if os.environ.get("PYARROW_BUILD_VERBOSE", "0") == "1":
                    cmake_options.append("-DCMAKE_VERBOSE_MAKEFILE=ON")
                # if os.environ.get("PYARROW_PARALLEL"):
                #     build_tool_args.append(
                #         "-j{0}".format(os.environ["PYARROW_PARALLEL"])
                #     )

                PYARROW_PARALLEL = 8
                build_tool_args.append("--")
                build_tool_args.append("-j{0}".format(PYARROW_PARALLEL))

            # Generate the build files
            print("-- Running cmake for PyArrow")
            self.spawn(
                ["emcmake", "cmake"] + extra_cmake_args + cmake_options + [source]
            )
            print("-- Finished cmake for PyArrow")

            print("-- Running cmake --build for PyArrow")
            self.spawn(
                ["cmake", "--build", ".", "--config", self.build_type] + build_tool_args
            )
            print("-- Finished cmake --build for PyArrow")

            # Move the libraries to the place expected by the Python build
            try:
                os.makedirs(pjoin(build_lib, "pyarrow"))
            except OSError:
                pass

            def copy_libs(dir):
                for path in os.listdir(pjoin(env_prefix, dir)):
                    if "arrow" in path.lower():
                        pyarrow_path = pjoin(build_lib, "pyarrow", path)
                        if os.path.exists(pyarrow_path):
                            os.remove(pyarrow_path)
                        pyarrow_cpp_path = pjoin(env_prefix, dir, path)
                        print(f"Copying {pyarrow_cpp_path} to {pyarrow_path}")
                        shutil.copy(pyarrow_cpp_path, pyarrow_path)

            # Move libraries to python/pyarrow
            # For windows builds, move DLL from bin/
            try:
                copy_libs("bin")
            except OSError:
                pass
            copy_libs("lib")

            if sys.platform == "win32":
                build_prefix = ""
            else:
                build_prefix = self.build_type

            if self.bundle_arrow_cpp or self.bundle_arrow_cpp_headers:
                arrow_cpp_include = pjoin(build_prefix, "include")
                print("Bundling includes: " + arrow_cpp_include)
                pyarrow_include = pjoin(build_lib, "pyarrow", "include")
                if os.path.exists(pyarrow_include):
                    shutil.rmtree(pyarrow_include)
                shutil.move(arrow_cpp_include, pyarrow_include)

                # pyarrow/include file is first deleted in the previous step
                # so we need to add the PyArrow C++ include folder again
                pyarrow_cpp_include = pjoin(env_prefix, "include")
                shutil.move(
                    pjoin(pyarrow_cpp_include, "arrow", "python"),
                    pjoin(pyarrow_include, "arrow", "python"),
                )

            # Move the built C-extension to the place expected by the Python
            # build
            self._found_names = []
            for name in self.CYTHON_MODULE_NAMES:
                built_path = self.get_ext_built(name)
                if not os.path.exists(built_path):
                    print("Did not find {0}".format(built_path))
                    if self._failure_permitted(name):
                        print("Cython module {0} failure permitted".format(name))
                        continue
                    raise RuntimeError(
                        "PyArrow C-extension failed to build:",
                        os.path.abspath(built_path),
                    )

                # The destination path to move the built C extension to
                ext_path = pjoin(build_lib, self._get_cmake_ext_path(name))
                if os.path.exists(ext_path):
                    os.remove(ext_path)
                self.mkpath(os.path.dirname(ext_path))

                if self.bundle_cython_cpp:
                    self._bundle_cython_cpp(name, build_lib)

                print("Moving built C-extension", built_path, "to build path", ext_path)
                shutil.move(built_path, ext_path)
                self._found_names.append(name)

                if os.path.exists(self.get_ext_built_api_header(name)):
                    shutil.move(
                        self.get_ext_built_api_header(name),
                        pjoin(os.path.dirname(ext_path), name + "_api.h"),
                    )

            if self.bundle_arrow_cpp:
                self._bundle_arrow_cpp(build_prefix, build_lib)

            if self.with_plasma and self.bundle_plasma_executable:
                # Move the plasma store
                source = os.path.join(self.build_type, "plasma-store-server")
                target = os.path.join(
                    build_lib, self._get_build_dir(), "plasma-store-server"
                )
                shutil.move(source, target)

    def _bundle_arrow_cpp(self, build_prefix, build_lib):
        print(pjoin(build_lib, "pyarrow"))
        move_shared_libs(build_prefix, build_lib, "arrow")
        move_shared_libs(build_prefix, build_lib, "arrow_python")
        if self.with_cuda:
            move_shared_libs(build_prefix, build_lib, "arrow_cuda")
        if self.with_substrait:
            move_shared_libs(build_prefix, build_lib, "arrow_substrait")
        if self.with_flight:
            move_shared_libs(build_prefix, build_lib, "arrow_flight")
        if self.with_dataset:
            move_shared_libs(build_prefix, build_lib, "arrow_dataset")
        if self.with_plasma:
            move_shared_libs(build_prefix, build_lib, "plasma")
        if self.with_gandiva:
            move_shared_libs(build_prefix, build_lib, "gandiva")
        if self.with_parquet and not self.with_static_parquet:
            move_shared_libs(build_prefix, build_lib, "parquet")
        if not self.with_static_boost and self.bundle_boost:
            move_shared_libs(
                build_prefix,
                build_lib,
                "{}_regex".format(self.boost_namespace),
                implib_required=False,
            )

    def _bundle_cython_cpp(self, name, lib_path):
        cpp_generated_path = self.get_ext_generated_cpp_source(name)
        if not os.path.exists(cpp_generated_path):
            raise RuntimeError(
                "expected to find generated C++ file "
                "in {0!r}".format(cpp_generated_path)
            )

        # The destination path to move the generated C++ source to
        # (for Cython source coverage)
        cpp_path = pjoin(
            lib_path, self._get_build_dir(), os.path.basename(cpp_generated_path)
        )
        if os.path.exists(cpp_path):
            os.remove(cpp_path)
        print(
            "Moving generated C++ source", cpp_generated_path, "to build path", cpp_path
        )
        shutil.move(cpp_generated_path, cpp_path)

    def _failure_permitted(self, name):
        if name == "_parquet" and not self.with_parquet:
            return True
        if name == "_parquet_encryption" and not self.with_parquet_encryption:
            return True
        if name == "_plasma" and not self.with_plasma:
            return True
        if name == "_orc" and not self.with_orc:
            return True
        if name == "_flight" and not self.with_flight:
            return True
        if name == "_substrait" and not self.with_substrait:
            return True
        if name == "_gcsfs" and not self.with_gcs:
            return True
        if name == "_s3fs" and not self.with_s3:
            return True
        if name == "_hdfs" and not self.with_hdfs:
            return True
        if name == "_dataset" and not self.with_dataset:
            return True
        if name == "_dataset_orc" and not (self.with_orc and self.with_dataset):
            return True
        if name == "_dataset_parquet" and not (self.with_parquet and self.with_dataset):
            return True
        if name == "_cuda" and not self.with_cuda:
            return True
        if name == "gandiva" and not self.with_gandiva:
            return True
        return False

    def _get_build_dir(self):
        # Get the package directory from build_py
        build_py = self.get_finalized_command("build_py")
        return build_py.get_package_dir("pyarrow")

    def _get_cmake_ext_path(self, name):
        # This is the name of the arrow C-extension
        filename = name + ext_suffix
        return pjoin(self._get_build_dir(), filename)

    def get_ext_generated_cpp_source(self, name):
        if sys.platform == "win32":
            head, tail = os.path.split(name)
            return pjoin(head, tail + ".cpp")
        else:
            return pjoin(name + ".cpp")

    def get_ext_built_api_header(self, name):
        if sys.platform == "win32":
            head, tail = os.path.split(name)
            return pjoin(head, tail + "_api.h")
        else:
            return pjoin(name + "_api.h")

    def get_ext_built(self, name):
        if sys.platform == "win32":
            head, tail = os.path.split(name)
            # Visual Studio seems to differ from other generators in
            # where it places output files.
            if self.cmake_generator.startswith("Visual Studio"):
                return pjoin(head, self.build_type, tail + ext_suffix)
            else:
                return pjoin(head, tail + ext_suffix)
        else:
            return f"release/{name}.so"
            return pjoin(self.build_type, name + ext_suffix)

    def get_names(self):
        return self._found_names

    def get_outputs(self):
        # Just the C extensions
        # regular_exts = _build_ext.get_outputs(self)
        return [self._get_cmake_ext_path(name) for name in self.get_names()]


def move_shared_libs(build_prefix, build_lib, lib_name, implib_required=True):
    if sys.platform == "win32":
        # Move all .dll and .lib files
        libs = [lib_name + ".dll"]
        if implib_required:
            libs.append(lib_name + ".lib")
        for filename in libs:
            shutil.move(
                pjoin(build_prefix, filename), pjoin(build_lib, "pyarrow", filename)
            )
    else:
        _move_shared_libs_unix(build_prefix, build_lib, lib_name)


def _move_shared_libs_unix(build_prefix, build_lib, lib_name):
    shared_library_prefix = "lib"
    if sys.platform == "darwin":
        shared_library_suffix = ".dylib"
    else:
        shared_library_suffix = ".so"

    lib_filename = shared_library_prefix + lib_name + shared_library_suffix
    # Also copy libraries with ABI/SO version suffix
    if sys.platform == "darwin":
        lib_pattern = (
            shared_library_prefix + lib_name + ".*" + shared_library_suffix[1:]
        )
        libs = glob.glob(pjoin(build_prefix, lib_pattern))
    else:
        libs = glob.glob(pjoin(build_prefix, lib_filename) + "*")

    if not libs:
        raise Exception(
            "Could not find library:" + lib_filename + " in " + build_prefix
        )

    # Longest suffix library should be copied, all others ignored and can be
    # symlinked later after the library has been installed
    libs.sort(key=lambda s: -len(s))
    print(libs, libs[0])
    lib_filename = os.path.basename(libs[0])
    shutil.move(
        pjoin(build_prefix, lib_filename), pjoin(build_lib, "pyarrow", lib_filename)
    )


# If the event of not running from a git clone (e.g. from a git archive
# or a Python sdist), see if we can set the version number ourselves
default_version = "11.0.0-SNAPSHOT"
if not os.path.exists("../.git") and not os.environ.get(
    "SETUPTOOLS_SCM_PRETEND_VERSION"
):
    os.environ["SETUPTOOLS_SCM_PRETEND_VERSION"] = default_version.replace(
        "-SNAPSHOT", "a0"
    )


# See https://github.com/pypa/setuptools_scm#configuration-parameters
scm_version_write_to_prefix = os.environ.get(
    "SETUPTOOLS_SCM_VERSION_WRITE_TO_PREFIX", setup_dir
)


def parse_git(root, **kwargs):
    """
    Parse function for setuptools_scm that ignores tags for non-C++
    subprojects, e.g. apache-arrow-js-XXX tags.
    """
    from setuptools_scm.git import parse

    kwargs[
        "describe_command"
    ] = 'git describe --dirty --tags --long --match "apache-arrow-[0-9]*.*"'
    return parse(root, **kwargs)


def guess_next_dev_version(version):
    if version.exact:
        return version.format_with("{tag}")
    else:

        def guess_next_version(tag_version):
            return default_version.replace("-SNAPSHOT", "")

        return version.format_next_version(guess_next_version)


with open("README.md") as f:
    long_description = f.read()


class BinaryDistribution(Distribution):
    def has_ext_modules(foo):
        return True


install_requires = ("numpy >= 1.16.6",)


# Only include pytest-runner in setup_requires if we're invoking tests
if {"pytest", "test", "ptr"}.intersection(sys.argv):
    setup_requires = ["pytest-runner"]
else:
    setup_requires = []


if strtobool(os.environ.get("PYARROW_INSTALL_TESTS", "1")):
    packages = find_namespace_packages(include=["pyarrow*"])
    exclude_package_data = {}
else:
    packages = find_namespace_packages(include=["pyarrow*"], exclude=["pyarrow.tests*"])
    # setuptools adds back importable packages even when excluded.
    # https://github.com/pypa/setuptools/issues/3260
    # https://github.com/pypa/setuptools/issues/3340#issuecomment-1219383976
    exclude_package_data = {"pyarrow": ["tests*"]}


setup(
    name="pyarrow",
    packages=packages,
    zip_safe=False,
    package_data={"pyarrow": ["*.pxd", "*.pyx", "includes/*.pxd"]},
    include_package_data=True,
    exclude_package_data=exclude_package_data,
    distclass=BinaryDistribution,
    # Dummy extension to trigger build_ext
    ext_modules=[Extension("__dummy__", sources=[])],
    cmdclass={"build_ext": build_ext},
    entry_points={
        "console_scripts": ["plasma_store = pyarrow:_plasma_store_entry_point"]
    },
    use_scm_version={
        "root": os.path.dirname(setup_dir),
        "parse": parse_git,
        "write_to": os.path.join(
            scm_version_write_to_prefix, "pyarrow/_generated_version.py"
        ),
        "version_scheme": guess_next_dev_version,
    },
    setup_requires=["setuptools_scm", "cython >= 0.29"] + setup_requires,
    install_requires=install_requires,
    tests_require=["pytest", "pandas", "hypothesis"],
    python_requires=">=3.7",
    description="Python library for Apache Arrow",
    long_description=long_description,
    long_description_content_type="text/markdown",
    classifiers=[
        "License :: OSI Approved :: Apache Software License",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    license="Apache License, Version 2.0",
    maintainer="Apache Arrow Developers",
    maintainer_email="dev@arrow.apache.org",
    test_suite="pyarrow.tests",
    url="https://arrow.apache.org/",
    project_urls={
        "Documentation": "https://arrow.apache.org/docs/python",
        "Source": "https://github.com/apache/arrow",
    },
)
