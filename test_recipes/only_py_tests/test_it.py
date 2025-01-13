# def test_imports():
#     import matplotlib.pyplot as plt

#     import pandas
#     from pandas import read_csv, DataFrame

#     import pyarrow as pa

#     import pkgutil
#     import scipy.interpolate
#     import scipy

#     for submodule in pkgutil.iter_modules(scipy.__path__):
#         __import__(f"scipy.{submodule.name}")

#     import IPython
#     from IPython.core.displayhook import DisplayHook
#     from IPython.core.displaypub import DisplayPublisher


def test_import():
    import numpy as np