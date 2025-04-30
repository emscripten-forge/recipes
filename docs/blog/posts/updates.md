---
date: 2025-04-30
category:
    - server
    - python
    - compiler
    
authors:
    - derthorsten
---

# Major updates

## We moved to prefix.dev

When emscripten-forge started, packages where build
hosted on a [quetz packge server](https://beta.mamba.pm/channels/conda-forge/packages/setuptools). Now we moved to [prefix.dev](https://prefix.dev/)

## We changed the default compiler

We changed the default emscripten-compiler we use to 3.1.73. Before that we used
3.1.45. Its a bit unfortunate that emscripten 4 landed in the middle of this
release. 

## We changed the default python version to 3.13

We changed the default python version to 3.13. Before that we used 3.11

