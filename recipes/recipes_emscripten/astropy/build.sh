#!/bin/bash


DISABLED=-Wno-incompatible-function-pointer-types


# Create the test() function
from .tests.runner import TestRunner

test = TestRunner.make_test_runner_in(__path__[0])


sed -i 's\from .tests.runner import TestRunner\# from .tests.runner import TestRunner\g' astropy/__init__.py
sed -i 's\test = TestRunner.make_test_runner_in(__path__[0])\# test = TestRunner.make_test_runner_in(__path__[0])\g' astropy/__init__.py


export CFLAGS="$CFLAGS     $DISABLED"
export CXXFLAGS="$CXXFLAGS $DISABLED"

${PYTHON}  -m pip install . --no-deps  -vvv
