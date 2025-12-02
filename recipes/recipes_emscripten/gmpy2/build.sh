#!/bin/bash



cp -r $RECIPE_DIR/test_gmpy2.py $SRC_DIR/test_gmpy2.py


${PYTHON} -m pip install . -vvv
