import sys
from logging import warning
from pathlib import Path

from oras import Oras

# initializations
owner = sys.argv[1]
target_platform = str(sys.argv[2])
conda_prefix = sys.argv[3]
token = sys.argv[4]

# create oras object and login with the token
oras = Oras(owner, token, conda_prefix, target_platform)

oras.login()

directory = "conda-bld"
location = Path(conda_prefix) / directory / target_platform

# push the all found packages to the registry
for data in location.iterdir():
    strFile = str(data)
    warning(f"data: strFile")
    if strFile.endswith("tar.bz2"):
        oras.push(target_platform, data)
