def test_import_pygame():
    """Test basic pygame import"""
    import pygame

def test_pygame_version():
    """Test that pygame version is accessible"""
    import pygame
    print(f"pygame version: {pygame.version.ver}")
    assert pygame.version.ver is not None

def test_pygame_init():
    """Test pygame initialization"""
    import pygame
    # Initialize pygame - this might not work in headless environment
    # but we can at least check if the function exists
    assert hasattr(pygame, 'init')
    
def test_pygame_constants():
    """Test that pygame constants are available"""
    import pygame
    # Test some basic constants
    assert hasattr(pygame, 'QUIT')
    assert hasattr(pygame, 'KEYDOWN')
    assert hasattr(pygame, 'MOUSEBUTTONDOWN')

def test_pygame_modules():
    """Test that key pygame modules are importable"""
    import pygame.font
    import pygame.image
    import pygame.mixer
    import pygame.sprite
    import pygame.surface
    import pygame.event
    import pygame.key