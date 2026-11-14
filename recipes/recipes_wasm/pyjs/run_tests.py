# Entry of the recipe test (pyjs_code_runner --async-main): runs the pyjs test
# suite (tests/ of the source) without the parts that need the pyjs test
# driver: the JS tests (ES modules imported over http) and the downloads of
# /test-data/all_bytes.bin (a file the driver serves).
import sys
from pathlib import Path

TESTS = Path(__file__).resolve().parent / "tests"
sys.path.insert(0, str(TESTS))

import pytest

import main as suite

# async tests downloading /test-data/all_bytes.bin
SKIP_ASYNC = {"test_jspi_run_sync_fetch"}

# sync tests downloading /test-data/all_bytes.bin
SKIP_SYNC = (
    "reference_download or xhr_like_urllib3 or urllib3_request"
    " or requests_get or pooch_retrieve or pyodide_http"
)


def drop_async_tests():
    """hide the SKIP_ASYNC tests from the suite's async runner"""
    load_module = suite.load_module

    def load_without_skipped(path):
        module = load_module(path)
        for name in SKIP_ASYNC:
            if hasattr(module, name):
                delattr(module, name)
        return module

    suite.load_module = load_without_skipped


async def main():
    """run the async + sync tests, raise if one failed"""
    drop_async_tests()
    suite.section("ASYNC TESTS")
    async_counts = await suite.run_async_tests()
    print(async_counts, flush=True)

    suite.section("SYNC TESTS (pytest)")
    exit_code = pytest.main(
        ["-s", "-vv", "-p", "no:faulthandler", "-p", "no:cacheprovider",
         "-k", f"not ({SKIP_SYNC})", str(TESTS / "sync")]
    )
    if async_counts.get("failed") or exit_code != 0:
        raise RuntimeError(f"tests failed: async {async_counts}, pytest exit code {exit_code}")
    return 0
