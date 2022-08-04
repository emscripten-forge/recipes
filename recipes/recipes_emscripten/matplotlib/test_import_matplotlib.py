
def test_matplotlib():
    from pathlib import Path

    import matplotlib
    import mpl_toolkits

    assert (Path(matplotlib.__file__).parent / 'fontlist.json').exists()

    import matplotlib.pyplot as plt
    import numpy as np

    fig = plt.figure()
    plt.plot(np.sin(np.linspace(0, 20, 100)))
    plt.show();
