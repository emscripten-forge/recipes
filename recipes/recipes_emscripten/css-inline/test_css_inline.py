def test_inline_html():
    import css_inline

    html = """<html>
  <head>
    <style>h1 { color:blue; }</style>
  </head>
  <body>
    <h1>Big Text</h1>
  </body>
</html>"""

    assert '<h1 style="color: blue;">Big Text</h1>' in css_inline.inline(html)


def test_inline_keeps_unrelated_markup():
    import css_inline

    html = "<style>p { margin: 0; }</style><p>hi</p><div>x</div>"
    out = css_inline.inline(html)
    assert 'style="margin: 0;"' in out
    assert "<div>x</div>" in out
