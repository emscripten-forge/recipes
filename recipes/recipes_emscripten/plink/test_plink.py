"""The Tk editor cannot run in the browser; check the parts that do.

SnapPy imports ``plink.LinkManager`` unconditionally, so this needs to keep
working even though ``plink.gui`` warns that tkinter is unavailable.
"""


def test_import_plink():
    import plink

    assert plink.__version__ == '2.4.9'


def test_link_manager_is_usable_without_tk():
    from plink import LinkManager

    manager = LinkManager()
    assert manager.Vertices == []
    assert manager.Arrows == []
    assert manager.Crossings == []
    assert manager.DT_code() is None


def test_public_names():
    import plink

    for name in ['LinkManager', 'LinkViewer', 'LinkEditor']:
        assert hasattr(plink, name), name
