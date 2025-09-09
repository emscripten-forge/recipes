import ppl

def test_basic_import():
    """Test that ppl can be imported and basic classes are available."""
    # Test basic imports
    assert hasattr(ppl, 'Variable')
    assert hasattr(ppl, 'Linear_Expression')
    assert hasattr(ppl, 'C_Polyhedron')
    assert hasattr(ppl, 'Constraint')
    assert hasattr(ppl, 'Generator')

def test_basic_functionality():
    """Test basic ppl functionality."""
    try:
        # Test basic PPL operations
        x = ppl.Variable(0)
        y = ppl.Variable(1)
        
        # Create a simple constraint
        cs = ppl.Constraint_System()
        cs.insert(x >= 0)
        cs.insert(y >= 0)
        cs.insert(x + y <= 1)
        
        # Create a polyhedron
        poly = ppl.C_Polyhedron(cs)
        
        # Basic check - should not raise an exception
        assert poly is not None
        print("Basic PPL functionality test passed")
    except Exception as e:
        print(f"Basic functionality test failed: {e}")
        raise

if __name__ == "__main__":
    test_basic_import()
    test_basic_functionality()
    print("All tests passed!")