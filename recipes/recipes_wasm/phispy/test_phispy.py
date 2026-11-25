import random


def _dna_with_repeat():
    rng = random.Random(1)

    def rand_seq(n):
        return "".join(rng.choice("ACGT") for _ in range(n))

    repeat = rand_seq(40)
    return rand_seq(200) + repeat + rand_seq(200) + repeat + rand_seq(200)


def test_phispy_import():
    import PhiSpyModules
    from PhiSpyModules import version

    assert version.__version__ == "5.0.10"


def test_phispy_submodules_import():
    from PhiSpyModules import classification, helper_functions, main  # noqa: F401
    import PhiSpyRepeatFinder  # noqa: F401


def test_repeat_finder_detects_repeat():
    import PhiSpyRepeatFinder

    repeats = PhiSpyRepeatFinder.repeatFinder(_dna_with_repeat(), 3, 20, 1, False)

    assert isinstance(repeats, list)
    assert len(repeats) > 0
    hit = repeats[0]
    assert set(hit) == {"repeat_number", "first_start", "first_end", "second_start", "second_end"}
    assert hit["second_start"] > hit["first_end"]
