#!/bin/bash
set -euxo pipefail

"${PYTHON}" -m pip install . ${PIP_ARGS}
