#!/bin/bash
set -e

RECIPE_DIR=$1
echo $RECIPE_DIR
echo  "${*:2}"
boa build $RECIPE_DIR ${@:2}
python browser_test_package.py $RECIPE_DIR
python better_test_package.py $RECIPE_DIR