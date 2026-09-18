def test_low_index():
    import low_index

    # Z^2 = <a, b | [a, b]> has exactly three subgroups of index 2, plus
    # the group itself, so four conjugacy classes of index at most 2.
    #
    # num_threads is left at its default of 0, which is what SnapPy passes.
    # That resolves to hardware_concurrency() upstream and would select the
    # multi-threaded SimsTree; this build patches it to stay single
    # threaded, and this call is what checks that the patch took.
    reps = low_index.permutation_reps(2, ['aBAb'], [], 2)
    assert len(reps) == 4
