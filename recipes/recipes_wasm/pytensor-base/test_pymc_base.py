import ctypes
import io

import numpy as np
import pytest


@pytest.fixture
def global_nrt():
    import numba  # noqa: F401

    # Numba's array runtime is only visible to JIT code when its extension was
    # loaded globally; pytester's eager-preload modes load it locally.
    try:
        getattr(ctypes.CDLL(None), "NRT_adapt_ndarray_from_python")
    except AttributeError:
        pytest.skip("pytester eagerly preloaded Numba's NRT extension locally")


def test_import_pymc():
    import pymc as pm

    assert pm.__version__


def _model():
    import pymc as pm

    rng = np.random.default_rng(0)
    data = rng.normal(1.5, 1.0, size=50)
    with pm.Model() as model:
        mu = pm.Normal("mu", 0.0, 10.0)
        sigma = pm.HalfNormal("sigma", 5.0)
        pm.Normal("obs", mu, sigma, observed=data)
    return model


def test_sample_and_plot(global_nrt):
    import arviz as az
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import pymc as pm

    with _model():
        idata = pm.sample(
            draws=200, tune=200, chains=1, cores=1, progressbar=False, random_seed=0
        )
    mu = idata.posterior["mu"].values
    assert mu.shape == (1, 200)
    assert abs(mu.mean() - 1.5) < 0.5

    az.plot_dist(idata, var_names=["mu", "sigma"])
    buf = io.BytesIO()
    plt.savefig(buf, format="png")
    plt.close("all")
    assert buf.getvalue()[:8] == b"\x89PNG\r\n\x1a\n"
