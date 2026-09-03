import os
import sysconfig

from setuptools import Extension, setup

prefix = os.environ["PREFIX"]
py_ver = sysconfig.get_python_version()
py_nodot = py_ver.replace(".", "")

setup(
    ext_modules=[
        Extension(
            "mymodule",
            sources=["mymodule.cpp"],
            include_dirs=[
                f"{prefix}/include",
                f"{prefix}/include/python{py_ver}",
            ],
            extra_objects=[
                f"{prefix}/lib/libboost_python{py_nodot}-{py_nodot}.a",
            ],
            extra_compile_args=["-fexceptions"],
            extra_link_args=["-fexceptions"],
        )
    ],
)
