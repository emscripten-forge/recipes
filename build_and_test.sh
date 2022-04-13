#!/bin/bash
set -e

RECIPE_DIR=$1
echo $RECIPE_DIR
echo  "${*:2}"


tmpfile=$(mktemp /tmp/abc-script.XXXXXX)

boa build $RECIPE_DIR ${@:2} > $tmpfile
cat $tmpfile
if cat  $tmpfile | grep -q 'Skipping existing'; then
    echo "Skipping testing"
else
    echo "PWD A!"
    pwd
    python browser_test_package.py $RECIPE_DIR
    echo "PWD B!"
    pwd
    python better_test_package.py $RECIPE_DIR
fi

