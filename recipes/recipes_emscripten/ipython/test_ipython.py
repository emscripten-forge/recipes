import pytest
import pyjs


def test_import_ipython():
    import IPython
    from IPython.core.displayhook import DisplayHook
    from IPython.core.displaypub import DisplayPublisher
