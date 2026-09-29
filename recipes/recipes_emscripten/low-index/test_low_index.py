def test_import_low_index():
    import low_index

    assert low_index.version() == '1.3'


def test_free_group_subgroups():
    from low_index import permutation_reps

    # Conjugacy classes of subgroups of the free group F_3 of index <= 4.
    reps = permutation_reps(rank=3, short_relators=[], long_relators=[],
                            max_degree=4)
    assert len(reps) == 653


def test_relators_are_used():
    from low_index import permutation_reps

    # Z/5 = <a | a^5> has exactly two subgroups of index at most 4: itself
    # and, since 5 is prime, nothing else.
    reps = permutation_reps(rank=1, short_relators=['aaaaa'],
                            long_relators=[], max_degree=4)
    assert len(reps) == 1
