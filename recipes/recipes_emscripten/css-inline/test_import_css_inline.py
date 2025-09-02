import css_inline


def test_css_inline():
    """Test basic css_inline functionality."""
    # Test basic HTML with CSS
    html = '''
    <html>
    <head>
        <style>
            p { color: red; font-size: 16px; }
            .test { margin: 10px; }
        </style>
    </head>
    <body>
        <p class="test">Hello World</p>
    </body>
    </html>
    '''
    
    # Inline the CSS
    result = css_inline.inline(html)
    
    # Check that inline styles were applied
    assert 'style=' in result
    assert 'color:red' in result or 'color: red' in result
    print("css_inline basic functionality test passed")


if __name__ == "__main__":
    test_css_inline()