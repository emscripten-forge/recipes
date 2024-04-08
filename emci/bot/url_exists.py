import subprocess

def url_exists(url: str) -> bool:
    try:
        output = subprocess.check_output(
            ["wget", "--spider", url],
            stderr=subprocess.STDOUT,
            timeout=1,
        )
    except Exception:
        return False
    # For FTP servers an exception is not thrown
    if "No such file" in output.decode("utf-8"):
        return False
    if "not retrieving" in output.decode("utf-8"):
        return False

    return True