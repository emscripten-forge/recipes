import pytest
import sys

if __name__ == "__main__":


    retcode = pytest.main()
    if retcode != pytest.ExitCode.OK:
        raise RuntimeError(f"pytest failed with return code: {retcode}")
    

