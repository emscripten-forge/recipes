def test_imports():
    from debugpy.server import api  # noqa
    from _pydevd_bundle import pydevd_frame_utils
    from _pydevd_bundle.pydevd_suspended_frames import (
        SuspendedFramesManager,
        _FramesTracker,
    )

    import matplotlib.pyplot as plt

    import pandas
    from pandas import read_csv, DataFrame

    import pyarrow as pa

    import pkgutil
    import scipy

    for submodule in pkgutil.iter_modules(scipy.__path__):
        __import__(f"scipy.{submodule.name}")

    import IPython
    from IPython.core.displayhook import DisplayHook
    from IPython.core.displaypub import DisplayPublisher
