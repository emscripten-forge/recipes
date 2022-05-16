.. role:: bash(code)
   :language: bash

Folder Structure
=================

The generated project has the following folder structure

::

    pybox2d
      ├──azure-pipelines.yml                                # Ci script
      │
      ├──benchmark                                          # C++ benchmark code
      │   └── ...
      │
      ├──binder                                             # dockerfile for mybinder.org
      │   └── Dockerfile
      │
      ├──cmake                                              # Cmake script/modules
      │   └── ...
      │
      ├──CMakeLists.txt                                     # Main cmake list
      │
      ├──CONTRIBUTING.rst                                   # Introduction how to constribute
      │
      ├──pybox2dConfig.cmake.in # Script to make find_package(...) 
      │                                                     # work for this package 
      │
      ├──pybox2d.pc.in          # Packaging info
      │
      ├──pybox2d-dev-requirements.yml # List of development conda dependencies
      │
      ├──docker                                              # dockerfile for dockerhub
      │   └── Dockerfile
      ├──docs                                               # Sources for sphinx documentation
      │   └── ...
      │
      ├──examples                                           # C++ examples
      │   └── ...
      │
      ├──include                                            # C++ include directory for this folder
      │   └── ...
      │
      ├──LICENCE.txt                                        # License file
      │
      ├──python                                             # Python binding source code
      │   └── ...
      │
      ├──README.rst                                         # Readme shown on github
      │
      ├──readthedocs.yml                                    # Entry point for automated
      │                                                     # documentation build on readthedocs.org
      │
      ├──recipe                                             # Folder for conda recipes
      │   └── ...
      │
      └──test                                               # Folder containing C++ unit tests
          └── ...

