"""Run pytester with a Playwright timeout long enough for scipy.test()."""
import os

from playwright.async_api import Page

# pyjs_code_runner hardcodes 4 minutes, which is too short for SciPy's fast suite.
_TIMEOUT_MS = int(os.environ.get("PYTESTER_TIMEOUT_MS", "3600000"))
_orig_set_default_timeout = Page.set_default_timeout


def _set_default_timeout(self, timeout):
    _orig_set_default_timeout(self, max(int(timeout or 0), _TIMEOUT_MS))


Page.set_default_timeout = _set_default_timeout

from pytester.__main__ import main

if __name__ == "__main__":
    main()
