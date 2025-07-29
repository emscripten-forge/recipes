
def test_import_future():
    from future.builtins import iterators
    from future.utils import (old_div, istext, isbytes, native, PY2, PY3,
                            native_str, raise_, as_native_str, ensure_new_type,
                            bytes_to_native_str, raise_from)
    from future.tests.base import expectedFailurePY3
    from future.tests.base import unittest, skip26
