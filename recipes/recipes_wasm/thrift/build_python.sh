#!/bin/bash
set -e

# Navigate to Python library directory
cd lib/py

# Skip byte compilation to avoid distutils issues
export PYTHONDONTWRITEBYTECODE=1

# Install Python package
${PYTHON} -m pip install . ${PIP_ARGS} --no-compile
