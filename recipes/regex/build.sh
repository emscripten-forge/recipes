#!/bin/bash
unset PYTHON
PYTHON=${BUILD_PREFIX}/bin/python3.10

${BUILD_PREFIX}/bin/python3.10  -m ensurepip --upgrade
${BUILD_PREFIX}/bin/python3.10 -m pip install  --upgrade pip