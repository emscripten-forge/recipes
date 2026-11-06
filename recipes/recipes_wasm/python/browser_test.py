"""Run the python embed tests (python_tests.mjs) in headless browsers (playwright).

Serves the current directory (test_main_web.{js,wasm,data}, browser_test.html,
...) and checks per browser that all python tests pass and that the wasm-gc call
trampoline is used where wasm-gc is available (wasm32), which JSPI stack
switching (e.g. pyjs.run_sync) depends on.

Usage: python browser_test.py [browser ...]   (default: chromium,
or the space separated env var PYTHON_TEST_BROWSERS)
"""

import asyncio
import functools
import http.server
import os
import sys
import threading

from playwright.async_api import async_playwright

TIMEOUT_S = 300


def serve(directory):
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=directory)
    handler.log_message = lambda *args: None
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server, f"http://127.0.0.1:{server.server_address[1]}"


async def run_browser(p, browser_name, url):
    browser = await getattr(p, browser_name).launch(headless=True)
    try:
        page = await browser.new_page()
        page.on("console", lambda msg: print(f"  [{browser_name}] {msg.text}", flush=True))
        page.on("pageerror", lambda err: print(f"  [{browser_name}] PAGE ERROR {err}", flush=True))
        await page.goto(f"{url}/browser_test.html")
        await page.wait_for_function("() => typeof globalThis.runPythonTests === 'function'")
        return await asyncio.wait_for(page.evaluate("() => runPythonTests()"), TIMEOUT_S)
    finally:
        await browser.close()


async def main(browsers):
    server, url = serve(os.getcwd())
    errors = []
    try:
        async with async_playwright() as p:
            for browser_name in browsers:
                print(f"=== {browser_name}", flush=True)
                try:
                    res = await run_browser(p, browser_name, url)
                except Exception as err:
                    errors.append(f"{browser_name}: {err!r}")
                    continue
                print(
                    f"  {res['userAgent']}\n  pointer size {res['pointerSize']}, "
                    f"wasm-gc supported {res['wasmGcSupported']}, "
                    f"wasm-gc trampoline used {res['wasmGcTrampoline']}, "
                    f"JSPI supported {res['jspiSupported']}",
                    flush=True,
                )
                failed = [r["name"] for r in res["results"] if not r["ok"]]
                if failed:
                    errors.append(f"{browser_name}: python tests failed: {', '.join(failed)}")
                if res["pointerSize"] == 4 and res["wasmGcSupported"] and not res["wasmGcTrampoline"]:
                    errors.append(f"{browser_name}: wasm32 but the wasm-gc call trampoline is not used")
                if not failed:
                    print(f"  all {len(res['results'])} tests passed", flush=True)
    finally:
        server.shutdown()
    for error in errors:
        print(f"ERROR {error}", flush=True)
    return 1 if errors else 0


if __name__ == "__main__":
    browsers = sys.argv[1:] or os.environ.get("PYTHON_TEST_BROWSERS", "chromium").split()
    raise SystemExit(asyncio.run(main(browsers)))
