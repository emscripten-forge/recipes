import pytest
import os
import wasm_requests


in_node = "PYTEST_DRIVER_NODE" in os.environ


@pytest.mark.skipif(in_node, reason="requires browser not node")
def test_wasm_requests():

    # get with query params
    r = wasm_requests.get("https://httpbin.org/get", params=dict(foo="bar", fobar=1))
    result = r.json()
    headers = r.headers

    assert result["args"]["foo"] == "bar"
    assert result["args"]["fobar"] == "1"
