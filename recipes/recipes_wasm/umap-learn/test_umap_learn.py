import ctypes
from importlib.metadata import version

import numpy as np
import pytest


@pytest.fixture
def global_nrt():
    import numba  # noqa: F401

    # Numba's array runtime is only visible to JIT code when its extension was
    # loaded globally; pytester's eager-preload modes load it locally.
    # pynndescent runs JIT code at import time, so even `import umap` needs it.
    try:
        getattr(ctypes.CDLL(None), "NRT_adapt_ndarray_from_python")
    except AttributeError:
        pytest.skip("pytester eagerly preloaded Numba's NRT extension locally")


def test_metadata():
    assert version("umap-learn") == "0.5.12"


def test_import(global_nrt):
    import umap

    assert umap.UMAP is not None


def test_fit_transform(global_nrt):
    import umap
    from sklearn.datasets import load_digits

    X, y = load_digits(return_X_y=True)
    X, y = X[:200], y[:200]
    emb = umap.UMAP(n_neighbors=10, n_epochs=50, random_state=0).fit_transform(X)
    assert emb.shape == (200, 2)
    assert np.all(np.isfinite(emb))

    # the usual notebook view: a scatter plot of the embedding
    import io

    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots()
    ax.scatter(emb[:, 0], emb[:, 1], c=y, cmap="Spectral", s=5)
    buf = io.BytesIO()
    fig.savefig(buf, format="png")
    plt.close(fig)
    assert buf.getvalue()[:8] == b"\x89PNG\r\n\x1a\n"


def test_transform_new_points(global_nrt):
    import umap

    rng = np.random.default_rng(0)
    X = np.vstack([rng.normal(0, 1, (60, 5)), rng.normal(8, 1, (60, 5))])
    reducer = umap.UMAP(n_neighbors=8, n_epochs=50, random_state=0).fit(X)
    emb = reducer.transform(X[:10] + 0.01)
    assert emb.shape == (10, 2)
    # the two well separated blobs stay separated in the embedding
    centers = reducer.embedding_[:60].mean(0), reducer.embedding_[60:].mean(0)
    assert np.linalg.norm(centers[0] - centers[1]) > 1.0
