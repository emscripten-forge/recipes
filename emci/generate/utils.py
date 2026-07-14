import hashlib

import os
import re
import urllib.request

 
def get_spdx_license_text(spdx_id):
    """
    Fetches the official license text from the canonical spdx.org registry API
    and returns it as a string. Does not write to disk.
    
    :param spdx_id: The SPDX license identifier (e.g., 'MIT', 'GPL-3.0-only').
    :return: The license text as a string, or None if the request fails.
    """
    if not spdx_id or spdx_id == "Unknown" or spdx_id.startswith("LicenseRef-"):
        print(f"Cannot fetch text for non-standard license: {spdx_id}")
        return None
        
    # Handle dual-licensing (grab the first option as primary)
    if " OR " in spdx_id:
        primary_spdx = spdx_id.split(" OR ")[0].strip()
    else:
        primary_spdx = spdx_id

    # Official Canonical JSON Endpoint
    url = f"https://spdx.org/licenses/{primary_spdx}.json"
    
    try:
        req = urllib.request.Request(
            url, 
            headers={'User-Agent': 'Python-SPDX-Client/1.0'}
        )
        
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            
        # Extract and return only the raw plain text
        return data.get("licenseText")
        
    except Exception as e:
        print(f"Failed to fetch license text for {spdx_id} from spdx.org: {e}")
        return None


    
def get_pkg_sha256(pkg_blob):
    sha256_hash = hashlib.sha256()
    sha256_hash.update(pkg_blob)
    return sha256_hash.hexdigest()

