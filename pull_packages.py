import json
import logging
import sys
from pathlib import Path

from oras import Oras

# features = sys.argv[1]
owner = sys.argv[1]
# pkg_name=  str (sys.argv[2])
target_platform = str(sys.argv[2])
conda_prefix = sys.argv[3]
token = sys.argv[4]

directory = "conda-bld"
oras = Oras(owner, token, conda_prefix, target_platform)
oras.login()

base = Path(conda_prefix) / directory
# expl= #/home/runner/micromamba/envs/buildenv/ #conda-bld/
if not base.is_dir():
    logging.warning(f" {base}did NOT exist")
    base.mkdir(mode=511, parents=False, exist_ok=True)

path = base / target_platform
# expl=#/home/runner/micromamba/envs/buildenv/ #conda-bld/ #linux-aarch64/

if not path.is_dir:
    print(f" {path}did NOT exist")
    path.mkdir(mode=511, parents=False, exist_ok=True)(f" {base}did NOT exist")

# import json file
trgt = target_platform

with open("packages.json", "r") as read_file:
    packages_json = json.load(read_file)

packagesList = packages_json["pkgs"][trgt]

# strData = str(data)
for pkg in packages_json["pkgs"][trgt]:
    oras.pull(pkg, "latest", str(path))
