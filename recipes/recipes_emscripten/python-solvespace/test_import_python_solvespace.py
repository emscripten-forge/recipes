def test_import_python_solvespace():
    import python_solvespace
    from python_solvespace import SolverSystem, ResultFlag

    # Basic functionality test
    sys = SolverSystem()
    wp = sys.create_2d_base()
    
    # Test that we can get the degrees of freedom
    dof = sys.dof()
    assert isinstance(dof, int)
    
    print("python-solvespace import test passed!")