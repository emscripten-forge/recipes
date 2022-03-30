#!/bin/bash


function suppress
{
   rm --force /tmp/suppress.out 2> /dev/null; \
   ${1+"$@"} > /tmp/suppress.out 2>&1 || \
   cat /tmp/suppress.out; \
   rm /tmp/suppress.out;
}


# the directory of the script
FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# the temp directory used, within $FILE_DIR
# omit the -p parameter to create a temporal directory in the default location
WORK_DIR=`mktemp -d -p "$FILE_DIR"`

# WORK_DIR=$FILE_DIR/"WORK_DIR"
# mkdir -p $WORK_DIR

# check if tmp dir was created
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
  echo "Could not create temp dir"
  exit 1
fi

# deletes the temp directory
function cleanup {      
  rm -rf "$WORK_DIR"
  echo "Deleted temp working directory $WORK_DIR"
}



# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT


pushd $WORK_DIR


RECIPE_DIR=$1
MICROMAMBA_CMD=$2

PKG_NAME=$(python $FILE_DIR"/get_pkg_name.py" $RECIPE_DIR)

TEST_FILE=$RECIPE_DIR/test_*.py


TEST_PREFIX_DIR=$WORK_DIR"/test_prefix/"


#CREATE AN ENVIRONMENT
TEST_ENV_NAME=test_env_for_$PKG_NAME
suppress $MICROMAMBA_CMD create -p $TEST_PREFIX_DIR  --platform=emscripten-32 python embind11 atomicwrites $PKG_NAME --yes


pushd $CONDA_EMSDK_DIR
suppress ./emsdk activate 3.1.2
suppress source emsdk_env.sh
popd


suppress emboa pack python core $TEST_PREFIX_DIR --version=3.10 --export-name="global.Module"
suppress emboa pack file  $TEST_FILE  "/"  testdata --export-name="global.Module"

cp $TEST_PREFIX_DIR/bin/embed.js   .
sed -i -e 's/push(audioPlugin);/push(imagePlugin);/g' embed.js
cp $TEST_PREFIX_DIR/bin/embed.wasm .
cp $FILE_DIR/plain_py_package_test.js ./test.js
ls



node test.js  "/$(basename -- $TEST_FILE)"

popd
