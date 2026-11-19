import io

import numpy as np


def _data():
    rng = np.random.default_rng(0)
    X = rng.normal(size=(80, 4))
    y = 3 * X[:, 0] - 2 * X[:, 1] + 0.1 * rng.normal(size=80)
    return X, y


def test_extensions_import():
    from shap import _cext, _cutils  # noqa: F401


def test_tree_explainer_additivity():
    import shap
    from sklearn.ensemble import RandomForestRegressor

    X, y = _data()
    model = RandomForestRegressor(n_estimators=10, max_depth=4, random_state=0)
    model.fit(X, y)

    explainer = shap.TreeExplainer(model)
    sv = explainer.shap_values(X[:10])
    assert sv.shape == (10, 4)
    # SHAP values plus expected value reproduce the model output
    np.testing.assert_allclose(
        sv.sum(axis=1) + explainer.expected_value, model.predict(X[:10]), rtol=1e-5
    )
    # the two informative features dominate
    importance = np.abs(sv).mean(axis=0)
    assert set(np.argsort(importance)[-2:]) == {0, 1}


def test_kernel_explainer():
    import shap
    from sklearn.linear_model import LinearRegression

    X, y = _data()
    model = LinearRegression().fit(X, y)
    explainer = shap.KernelExplainer(model.predict, X[:20])
    sv = explainer.shap_values(X[:3], nsamples=100, silent=True)
    assert sv.shape == (3, 4)
    np.testing.assert_allclose(
        sv.sum(axis=1) + explainer.expected_value, model.predict(X[:3]), rtol=1e-4
    )


def test_permutation_explainer_and_plots():
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import shap
    from sklearn.tree import DecisionTreeRegressor

    X, y = _data()
    model = DecisionTreeRegressor(max_depth=3, random_state=0).fit(X, y)
    explanation = shap.Explainer(model.predict, X[:30], algorithm="permutation")(X[:10])
    assert explanation.values.shape == (10, 4)

    for plot in (shap.plots.beeswarm, shap.plots.bar):
        plot(explanation, show=False)
        buf = io.BytesIO()
        plt.savefig(buf, format="png")
        plt.close("all")
        assert buf.getvalue()[:8] == b"\x89PNG\r\n\x1a\n"

    shap.plots.waterfall(explanation[0], show=False)
    buf = io.BytesIO()
    plt.savefig(buf, format="png")
    plt.close("all")
    assert buf.getvalue()[:8] == b"\x89PNG\r\n\x1a\n"

    shap.summary_plot(explanation.values, X[:10], show=False)
    buf = io.BytesIO()
    plt.savefig(buf, format="png")
    plt.close("all")
    assert buf.getvalue()[:8] == b"\x89PNG\r\n\x1a\n"


def test_force_plot_html():
    import shap
    from sklearn.ensemble import RandomForestRegressor

    X, y = _data()
    model = RandomForestRegressor(n_estimators=5, max_depth=3, random_state=0).fit(X, y)
    explanation = shap.TreeExplainer(model)(X[:5])

    # single prediction and stacked force plots render as HTML/JS in notebooks
    for obj in (shap.plots.force(explanation[0]), shap.plots.force(explanation)):
        html = obj._repr_html_()
        assert "<div" in html and "SHAP" in html
    # shap.initjs() ships this bundle into the notebook; it must be in the VFS
    js = shap.getjs()
    assert js.startswith("<script") and len(js) > 10_000
