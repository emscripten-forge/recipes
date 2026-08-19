def test_umap_learn():
    import umap

    # Pytester also runs eager-preload modes. Those load Numba's CPython
    # extensions with RTLD_LOCAL, which prevents JIT-generated side modules
    # from resolving NRT allocator symbols. Exercise the public UMAP API in
    # every loader mode; the functional JIT path is covered in JupyterLite's
    # normal on-demand loading mode.
    model = umap.UMAP(
        n_neighbors=10,
        random_state=42,
        metric="euclidean",
        output_metric="euclidean",
        init="spectral",
    )

    assert model.n_neighbors == 10
    assert model.metric == "euclidean"
