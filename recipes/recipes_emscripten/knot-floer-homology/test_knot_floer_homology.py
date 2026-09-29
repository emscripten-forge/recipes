# The PD code from the upstream README; it describes a genus 2 knot.
PD = [(2, 0, 3, 15), (0, 6, 1, 5), (6, 2, 7, 1), (3, 10, 4, 11),
      (9, 4, 10, 5), (7, 12, 8, 13), (13, 8, 14, 9), (11, 14, 12, 15)]


def test_import_knot_floer_homology():
    import knot_floer_homology

    assert knot_floer_homology.__version__ == '1.2.2'


def test_pd_to_hfk():
    import knot_floer_homology

    answer = knot_floer_homology.pd_to_hfk(PD)
    assert answer['seifert_genus'] == 2
    assert answer['total_rank'] == 9
    assert answer['fibered'] is True
    assert answer['L_space_knot'] is False
    assert answer['tau'] == 0
    assert answer['ranks'] == {(-2, -2): 1, (-1, -1): 2, (0, 0): 3,
                               (1, 1): 2, (2, 2): 1}


def test_pd_to_morse():
    import knot_floer_homology

    morse = knot_floer_homology.pd_to_morse(PD)
    assert morse['girth'] > 0
    assert len(morse['events']) > 0
