```{image} assets/banner.svg
:alt: Emscripten-forge banner
:class: banner dark-light
```

# Introduction

Emscripten-forge is a GitHub [organization](https://github.com/emscripten-forge)/[repository](https://github.com/emscripten-forge/recipes) containing [conda recipes](https://github.com/emscripten-forge/recipes) for the `emscripten-wasm32` and `emscripten-wasm64` platforms.
Conda-forge does not (yet) support the `emscripten-wasm*` platforms. `emscripten-forge` fills this gap by providing a channel with conda packages for the `emscripten-wasm*` platforms.
The recipes repository not only stores the recipe files for multiple packages, but it also builds and uploads these packages to the `emscripten-forge` channel on [prefix.dev](https://prefix.dev/channels/emscripten-forge-6x)

```{admonition} Community project
Emscripten-forge strives to be a community project, shaped by its active individual and organizational supporters. Anyone can participate in the decision-making process openly through GitHub. See [Get Involved](project/get_involved.md) to learn how to participate as an individual or organisation.
```

```{toctree}
:caption: Development
:maxdepth: 1
development/adding_packages
development/recipe_format
development/local_builds
development/conda_build_config
development/troubleshooting
development/code_of_conduct
```

```{toctree}
:caption: Usage
:maxdepth: 1
usage/installing_packages
usage/jupyterlite
usage/package_server
usage/qtapp
```

```{toctree}
:caption: Project
:maxdepth: 1
blog/index
project/get_involved
project/related_projects
project/showcase
project/faq
project/credits
```

# Acknowledgements

Special thanks to [QuantStack](https://quantstack.net/), [Bloomberg](https://www.bloomberg.com/), and [prefix.dev](https://prefix.dev/), whose support made it possible to start the project. See [Credits](project/credits.md) for the current supporters and contributors.
