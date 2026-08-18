def require_global_nrt():
    import ctypes

    import pytest

    # Pytester also exercises eager-preload modes which load Numba's CPython
    # extensions with RTLD_LOCAL before they can be requested with RTLD_GLOBAL.
    try:
        getattr(ctypes.CDLL(None), "NRT_adapt_ndarray_from_python")
    except AttributeError:
        pytest.skip("pytester eagerly preloaded Numba's NRT extension locally")


def test_umap_learn():
    from sklearn.datasets import load_digits
    from sklearn.model_selection import train_test_split

    import umap

    require_global_nrt()

    digits = load_digits()
    X_train, X_test, y_train, y_test = train_test_split(
        digits.data, digits.target, stratify=digits.target, random_state=42
    )

    target_spaces = ["plane", "torus", "sphere"]


    trans = umap.UMAP(
        n_neighbors=10,
        random_state=42,
        metric="euclidean",
        output_metric="euclidean",
        init="spectral",
        verbose=True,
    ).fit(X_train)

    assert trans is not None
