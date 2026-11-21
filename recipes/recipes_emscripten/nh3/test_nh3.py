def test_clean():
    import nh3

    html = "<b><img src='' onerror='alert(\\'hax\\')'>I'm not trying to XSS you</b>"
    assert nh3.clean(html) == '<b><img src="">I\'m not trying to XSS you</b>'
    assert nh3.clean(html, tags={"img"}) == '<img src="">I\'m not trying to XSS you'
    assert (
        nh3.clean(html, tags={"img"}, attributes={}) == "<img>I'm not trying to XSS you"
    )
    assert nh3.clean(html, attributes={}) == "<b><img>I'm not trying to XSS you</b>"
    assert (
        nh3.clean('<a href="https://baidu.com">baidu</a>')
        == '<a href="https://baidu.com" rel="noopener noreferrer">baidu</a>'
    )
    assert (
        nh3.clean('<a href="https://baidu.com">baidu</a>', link_rel=None)
        == '<a href="https://baidu.com">baidu</a>'
    )
    assert (
        nh3.clean(
            "<script>alert('hello')</script><style>a { background: #fff }</style>",
            clean_content_tags={"script", "style"},
        )
        == ""
    )


def test_clean_generic_attribute_prefixes():
    import nh3

    assert (
        nh3.clean('<div data-v="foo"></div>', generic_attribute_prefixes={"data-"})
        == '<div data-v="foo"></div>'
    )


def test_clean_tag_attribute_values():
    import nh3

    assert (
        nh3.clean(
            "<my-tag my-attr=val>",
            tags={"my-tag"},
            tag_attribute_values={"my-tag": {"my-attr": {"val"}}},
        )
        == '<my-tag my-attr="val"></my-tag>'
    )
    assert (
        nh3.clean(
            "<my-tag>",
            tags={"my-tag"},
            set_tag_attribute_values={"my-tag": {"my-attr": "val"}},
        )
        == '<my-tag my-attr="val"></my-tag>'
    )


def test_is_html():
    import nh3

    assert nh3.is_html("<b>hi</b>")
    assert not nh3.is_html("plain text")
