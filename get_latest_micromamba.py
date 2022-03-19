import requests
import sys
import platform
import time
import os

from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry


TOKEN = os.getenv("GITHUB_TOKEN")

def requests_retry_session(
    retries=5,
    backoff_factor=0.2,
    status_forcelist=(500, 502, 504),
    session=None,
):
    session = session or requests.Session()
    retry = Retry(
        total=retries,
        read=retries,
        connect=retries,
        backoff_factor=backoff_factor,
        status_forcelist=status_forcelist,
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)
    return session


s = requests_retry_session()

nightly = False
if len(sys.argv) >= 2:
    nightly = sys.argv[1] == "nightly"

plat = platform.system()
if plat == "Linux":
    plat = "linux-64"
elif plat == "Darwin":
    plat = "osx-64"
elif plat == "Windows":
    plat = "win-64"

if not nightly:
    url = "https://api.github.com/repos/mamba-org/boa-forge/releases/latest"
else:
    url = "https://api.github.com/repos/mamba-org/boa-forge/releases"

def get_json():
    headers = {}
    if TOKEN:
        headers = {"authorization": f"Bearer {TOKEN}"}
    j = s.get(url, headers=headers).json()
    time.sleep(0.3)
    return j

release = None
j = get_json()
retries = 10
i = 0
while release == None and i < retries:
    if not nightly:
        release = j
    else:
        try:
            print(j, file=sys.stderr)
            release = j[0]
        except KeyError:
            print(j, file=sys.stderr)
            time.sleep(0.5)
            j = get_json()
            i += 1

print(f"Found release: {release['name']}", file=sys.stderr)
for asset in release["assets"]:
    if plat in asset["name"]:
        print(asset["browser_download_url"])
        sys.exit(0)