def test_import():
    from kiwisolver import Solver

def test_metadata_present():
    import pkg_resources
    distribution = pkg_resources.get_distribution("kiwisolver")
    assert distribution.version.split(".") > ["0", "0", "0", "0"]
