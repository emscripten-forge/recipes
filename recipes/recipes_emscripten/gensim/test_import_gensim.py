def test_gensim_import():
    """Test basic gensim import."""
    import gensim
    
def test_gensim_models():
    """Test basic model imports."""
    from gensim.models import Word2Vec
    from gensim.models import KeyedVectors
    
def test_gensim_utils():
    """Test basic utilities."""
    from gensim import utils
    from gensim.utils import simple_preprocess
    
    # Test simple preprocessing
    text = "This is a simple test sentence."
    tokens = simple_preprocess(text)
    assert isinstance(tokens, list)
    assert len(tokens) > 0
    assert 'simple' in tokens
    
def test_gensim_version():
    """Test that we can access version info."""
    import gensim
    # Should have a version attribute
    assert hasattr(gensim, '__version__')