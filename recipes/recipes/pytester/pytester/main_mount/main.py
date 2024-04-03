import pytest
import sys

async def main():


    retcode = pytest.main()
    if retcode != pytest.ExitCode.OK:
        raise RuntimeError(f"pytest failed with return code: {retcode}")
    

