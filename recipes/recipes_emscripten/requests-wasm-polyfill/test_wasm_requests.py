import pytest
import os
import requests
import pyjs


is_browser_worker = pyjs.js.Function('return typeof importScripts === "function"')()

skip_non_worker = pytest.mark.skipif(
    not is_browser_worker,
    reason="requires browser, not node",
)


@skip_non_worker
def test_wasm_requests():
    # get with query params
    r = requests.get("https://httpbin.org/get", params=dict(foo="bar", fobar=1))
    result = r.json()
    headers = r.headers

    assert result["args"]["foo"] == "bar"
    assert result["args"]["fobar"] == "1"
