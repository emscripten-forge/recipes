import pytest
from pathlib import Path

def test_matplotlib(tmp_path):
    tmp_path = Path(tmp_path)


    import matplotlib
    import mpl_toolkits

    assert (Path(matplotlib.__file__).parent / 'fontlist.json').exists()

    import matplotlib.pyplot as plt
    import numpy as np

    fig = plt.figure()
    plt.plot(np.sin(np.linspace(0, 20, 100)))
    plt.savefig(tmp_path / 'test.png')
    assert (tmp_path / 'test.png').exists()


def test_import_ft2font():
    import matplotlib.ft2font
    
    with pytest.raises(Exception):
        matplotlib.ft2font.__path__
