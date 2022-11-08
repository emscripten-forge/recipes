#!/bin/bash
cp setup.py python/setup.py
cd python
${PYTHON} -m pip install .