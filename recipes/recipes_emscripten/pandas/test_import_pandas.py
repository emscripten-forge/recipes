
def test_import_pandas():
    import pandas
    from pandas import read_csv

def test_pandas_series():
    from pandas import Series
    import numpy as np

    ser = Series()
    print("Pandas Series:", ser)
    data = np.array(['e', 'm', 'f', 'o', 'r', 'g', 'e'])
    ser = Series(data)
    print("Pandas Series:", ser)

def test_pandas_dataframe():
    from pandas import DataFrame

    df = pd.DataFrame()
    print("Pandas DataFrame:", df)
    data = ['emscripten', 'forge', 'packages', 'python']
    df = pd.DataFrame(data)
    print("Pandas DataFrame:", df)
