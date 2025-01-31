import pytest
import sys

if __name__ == "__main__":

    try:
        retcode = pytest.main()
    except Exception as e:
        print(f"pytest failed with exception: {e}")
        #  get backtrace
        exc_type, exc_value, exc_traceback = sys.exc_info()
        import traceback
        traceback.print_exception(exc_type, exc_value, exc_traceback)
        

        retcode = pytest.ExitCode.INTERRUPTED
        raise e
    


    if retcode != pytest.ExitCode.OK:
        raise RuntimeError(f"pytest failed with return code: {retcode}")
    

