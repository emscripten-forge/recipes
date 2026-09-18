def test_knot_floer_homology():
    import knot_floer_homology

    # The right-handed trefoil, as a PD code. Its knot Floer homology has
    # total rank 3, Seifert genus 1, and it is fibered and an L-space knot.
    trefoil = [(1, 4, 2, 5), (3, 6, 4, 1), (5, 2, 6, 3)]
    hfk = knot_floer_homology.pd_to_hfk(trefoil)

    assert hfk['total_rank'] == 3
    assert hfk['seifert_genus'] == 1
    assert hfk['fibered'] is True
    assert hfk['L_space_knot'] is True
