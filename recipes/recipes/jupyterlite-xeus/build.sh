#!/bin/bash

set -eux

pushd mambajs
    yarn install
    yarn run build
popd

pushd jupyterlite-xeus
    yarn link --relative ../mambajs --private
    yarn link --relative ../mambajs/packages/mambajs
    yarn link --relative ../mambajs/packages/mambajs-core
    cat package.json

    rm yarn.lock || true

    pip install . -vv --prefix $PREFIX
popd