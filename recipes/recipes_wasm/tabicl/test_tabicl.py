import numpy as np
import pytest

# A tiny randomly initialized model: enough to exercise the full
# fit/predict path without downloading a pretrained checkpoint.
SMALL_CONFIG = dict(
    embed_dim=16,
    col_num_blocks=1,
    col_nhead=2,
    col_num_inds=8,
    row_num_blocks=1,
    row_nhead=2,
    row_num_cls=2,
    icl_num_blocks=1,
    icl_nhead=2,
)


def _save_checkpoint(path, **config):
    import torch
    from tabicl._model.tabicl import TabICL

    torch.manual_seed(0)
    model = TabICL(**config)
    torch.save({"config": config, "state_dict": model.state_dict()}, path)
    return path


def _data(n=40, n_features=4):
    rng = np.random.default_rng(0)
    X = rng.normal(size=(n, n_features)).astype(np.float32)
    return X, rng


def test_import_without_psutil_and_hub():
    import tabicl
    from tabicl._model import inference

    assert tabicl.TabICLClassifier is not None
    # psutil is patched to be optional; the fallback memory estimate works.
    assert inference.psutil is None
    available_mb = inference.InferenceManager.get_available_cpu_memory(None)
    assert available_mb > 0


def test_classifier_with_local_checkpoint(tmp_path):
    from tabicl import TabICLClassifier

    ckpt = _save_checkpoint(tmp_path / "clf.ckpt", max_classes=10, **SMALL_CONFIG)
    X, rng = _data()
    y = rng.integers(0, 3, size=len(X))

    clf = TabICLClassifier(
        model_path=ckpt, allow_auto_download=False, n_estimators=2,
        device="cpu", use_amp=False,
    )
    clf.fit(X[:30], y[:30])
    proba = clf.predict_proba(X[30:])
    assert proba.shape == (10, 3)
    np.testing.assert_allclose(proba.sum(axis=1), 1.0, rtol=1e-4)
    assert set(clf.predict(X[30:])) <= {0, 1, 2}


def test_regressor_with_local_checkpoint(tmp_path):
    from tabicl import TabICLRegressor

    ckpt = _save_checkpoint(tmp_path / "reg.ckpt", max_classes=0, **SMALL_CONFIG)
    X, rng = _data()
    y = X.sum(axis=1)

    reg = TabICLRegressor(
        model_path=ckpt, allow_auto_download=False, n_estimators=2,
        device="cpu", use_amp=False,
    )
    reg.fit(X[:30], y[:30])
    pred = reg.predict(X[30:])
    assert pred.shape == (10,)
    assert np.all(np.isfinite(pred))


def test_isotonic_quantile_fix_uses_numba():
    import ctypes

    import torch
    from tabicl._model import quantile_dist

    # Numba's array runtime is only visible to JIT code when its extension was
    # loaded globally; pytester's eager-preload modes load it locally.
    try:
        getattr(ctypes.CDLL(None), "NRT_adapt_ndarray_from_python")
    except AttributeError:
        pytest.skip("pytester eagerly preloaded Numba's NRT extension locally")

    assert quantile_dist.NUMBA_AVAILABLE
    y = torch.tensor([[1.0, 3.0, 2.0, 4.0]])
    result = quantile_dist.isotonic_regression_pava(y)
    # PAVA pools the violating pair; the sort fallback would give 1, 2, 3, 4.
    torch.testing.assert_close(result, torch.tensor([[1.0, 2.5, 2.5, 4.0]]))


def test_download_without_hub_gives_clear_error():
    from tabicl import TabICLClassifier

    X, rng = _data()
    y = rng.integers(0, 2, size=len(X))
    with pytest.raises(ImportError, match="model_path"):
        TabICLClassifier(device="cpu").fit(X, y)
