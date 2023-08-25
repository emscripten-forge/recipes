def test_imports():
    import matplotlib.pyplot as plt

    import pandas
    from pandas import read_csv, DataFrame

    import pyarrow as pa

    import pkgutil
    import scipy

    for submodule in pkgutil.iter_modules(scipy.__path__):
        __import__(f"scipy.{submodule.name}")
