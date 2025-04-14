# Recipe format

Typically, a recipe is a directory with a `recipe.yaml` file that contains the information needed to build a package and optionally an additional `build.sh` script that is executed during the build process.

## recipe.yaml

The recipe.yaml file may look like this:
```yaml
context:
  version: "2022.1.18" # the version of the package
  name: "regex"        # the name of the package

package:
  name: ${{ name }}          # use the context variables defined above
  version: ${{ version }}    # use the context variables defined above

source:
  # the url is formed from a "template" with the context variables
  url: https://pypi.io/packages/source/r/${{ name }}/${{ name }}-${{ version }}.tar.gz
  sha256: 97f32dc03a8054a4c4a5ab5d761ed4861e828b2c200febd4e46857069a483916

build:
  number: 0

requirements:
  build:
    - python
    - cross-python_${{ target_platform }}
    - ${{ compiler("c") }}
    - pip
  host:
    - python
  run:
    - python

# to test a python package, we need to use the pytester package.
# this will run pytests in a headless browser
tests:
  - script: pytester
    requirements:
      build:
        - pytester
      run:
        - pytester-run
    files:
      recipe:
        - test_regex.py


about:
  homepage: https://bitbucket.org/mrabarnett/mrab-regex
  license: Apache-2.0
  summary: Alternative regular expression module, to replace re

extra:
  recipe-maintainers:
    - DerThorsten

```
## build.sh
The bash script may look like this:
```bash
#!/bin/bash

export LDFLAGS="-s MODULARIZE=1  -s LINKABLE=1  -s EXPORT_ALL=1 -s WASM=1 -std=c++14 -s SIDE_MODULE=1 -sWASM_BIGINT"
${PYTHON} -m pip install .
```