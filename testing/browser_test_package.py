import tempfile
import os
import yaml
import subprocess
import shutil

import http
from socket import *
from http.server import BaseHTTPRequestHandler, HTTPServer
import threading


import socket
from contextlib import closing
import threading
import functools

from http.server import HTTPServer, BaseHTTPRequestHandler
import ssl


HTML_FILE_STR = """<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>TEST_TITLE</title>
    <link rel="stylesheet" href="style.css">
    <script src="script.js"></script>
  </head>
  <body>
    <!-- page content -->
    <script type="application/javascript" src="pytest_driver.js"></script>
    <script type="application/javascript">


function waitRunDependency() {
  const promise = new Promise((r) => {
    Module.monitorRunDependencies = (n) => {
      if (n === 0) {
        r();
      }
    };
  });
  Module.addRunDependency("dummy");
  Module.removeRunDependency("dummy");
  return promise;
}
var pytestOutputString = ""
const print = (text) => {
  console.log(text)
  pytestOutputString += text;
  pytestOutputString += "\\n";
}
const sink = (text) =>{}

let res = (async function() {

    var opts = {}
    opts = {print:sink, error:sink};
    var myModule = await createModule({print:print,error:print})
    Module = myModule
    globalThis.Module = Module
    await import('./python_data.js')
    await import('./testdata.js')
    var deps = await waitRunDependency()

    myModule.initialize_interpreter()
    var ret = myModule.run_tests("/tests")

    var pytest_output = document.createElement('TEXTAREA');
    document.body.appendChild(pytest_output);
    pytest_output.setAttribute("name", "pytest_output");
    pytest_output.id = "pytest_output"
    pytest_output.value = pytestOutputString


    var pytest_retcode = document.createElement('TEXTAREA');
    document.body.appendChild(pytest_retcode);
    pytest_retcode.setAttribute("name", "pytest_retcode");
    pytest_retcode.id = "pytest_retcode"
    pytest_retcode.value = String(ret)

    return ret

})().then(
  (r) => {
    console.log("test r",r)
    if(r == 1)
    {
      throw "Test(s) failed!";
    }
  }
)




    </script>
  </body>
</html>
"""


def find_free_port():
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as s:
        s.bind(("", 0))
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        return s.getsockname()[1]


def serve_forever(httpd, work_dir, port):

    httpd.serve_forever()


def create_html(work_dir):
    # Write the file out again
    with open(os.path.join(work_dir, "test.html"), "w") as file:
        file.write(HTML_FILE_STR)


def get_pytest_files(recipe_dir, recipe):
    recipe_dir = os.path.abspath(recipe_dir)
    extra = recipe.get("extra", {})
    emscripten_tests = extra.get("emscripten_tests", {})
    python = emscripten_tests.get("python", {})
    pytest_files = python.get("pytest_files", [])
    pytest_files = [os.path.join(recipe_dir, f) for f in pytest_files]
    return pytest_files


def create_test_env(pkg_name, prefix):
    # cmd = ['$MAMBA_EXE' ,'create','--prefix', prefix,'--platform=emscripten-32'] + [pkg_name] #+ ['--dryrun']
    print("prefix", prefix)
    cmd = [
        f"$MAMBA_EXE create --yes --prefix {prefix} --platform=emscripten-32   python pytest_driver pytest {pkg_name}"
    ]
    ret = subprocess.run(cmd, shell=True)
    #  stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    returncode = ret.returncode
    assert returncode == 0


def pack(prefix, pytest_files):
    print("pytest_files", pytest_files)
    assert len(pytest_files) <= 1, "atm only one file is allowed"

    cmd = [f"emperator pack python core {prefix} --version=3.10 "]
    ret = subprocess.run(cmd, shell=True)

    cmd = [f"emperator pack file  {pytest_files[0]}  '/tests'  testdata"]
    ret = subprocess.run(cmd, shell=True)


def copy_from_prefix(prefix, work_dir):
    # copy wasm / js file to work dir
    js_file = os.path.join(prefix, "bin", "pytest_driver.js")
    shutil.copy(js_file, work_dir)
    wasm_file = os.path.join(prefix, "bin", "pytest_driver.wasm")
    shutil.copy(wasm_file, work_dir)


def start_server(work_dir, port):
    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=work_dir, **kwargs)

        def log_message(self, format, *args):
            return

    httpd = HTTPServer(("localhost", port), Handler)

    thread = threading.Thread(
        target=functools.partial(
            serve_forever, httpd=httpd, work_dir=work_dir, port=port
        )
    )
    thread.start()
    return thread, httpd


CONF = """// @ts-check

/** @type {import('@playwright/test').PlaywrightTestConfig} */
const config = {
  use: {
    headless: false,
    viewport: { width: 1280, height: 720 },
    ignoreHTTPSErrors: true,
    video: 'on-first-retry',
  },
};

module.exports = config;
"""

import sys
import asyncio
from playwright.async_api import async_playwright
from playwright.async_api import Page


async def playwright_main(page_url, run_forever=True):
    async with async_playwright() as p:
        # browser = await p.chromium.launch(headless=False, slow_mo=100)
        browser = await p.chromium.launch()
        page = await browser.new_page()
        page.set_default_timeout(60000)
        page.set_default_navigation_timeout(60000)
        await page.goto(page_url)

        pytest_output = await page.locator("id=pytest_output").input_value()
        print("pytest_output", pytest_output)

        pytest_retcode = await page.locator("id=pytest_retcode").input_value()
        print("pytest_retcode", pytest_retcode)
        # if pytest_retcode != "0":
        #     print("tests failed")
        #     return int(pytest_retcode)

        await browser.close()

        # if False and run_forever:
        #     print('Press CTRL-D to stop')
        #     reader = asyncio.StreamReader()
        #     pipe = sys.stdin
        #     loop = asyncio.get_event_loop()
        #     await loop.connect_read_pipe(lambda: asyncio.StreamReaderProtocol(reader), pipe)
        #     async for line in reader:
        #         print(f'Got: {line.decode()!r}')
        # else:
        #     await browser.close()


def run_playwright_tests(work_dir, port):
    # Write the file out again
    page_url = f"http://0.0.0.0:{port}/test.html"
    os.chdir(work_dir)

    asyncio.run(playwright_main(page_url=page_url))


def test_package(recipe_dir):
    assert os.path.isdir(recipe_dir)
    recipe_file = os.path.join(recipe_dir, "recipe.yaml")

    has_tests = False
    with open(recipe_file, "r") as stream:
        recipe = yaml.safe_load(stream)
    pytest_files = get_pytest_files(recipe_dir, recipe)
    has_tests = len(pytest_files) > 0

    if has_tests:
        pkg_name = recipe["package"]["name"]
        with tempfile.TemporaryDirectory() as temp_dir:

            prefix = os.path.join(temp_dir, "prefix")
            work_dir = os.path.join(temp_dir, "work")
            os.mkdir(work_dir)
            os.chdir(work_dir)
            create_test_env(pkg_name=pkg_name, prefix=prefix)
            pack(prefix=prefix, pytest_files=pytest_files)
            port = find_free_port()
            create_html(work_dir=work_dir)

            thread, server = start_server(work_dir=work_dir, port=port)
            try:
                copy_from_prefix(prefix=prefix, work_dir=work_dir)
                run_playwright_tests(work_dir=work_dir, port=port)
            finally:
                server.shutdown()
                thread.join()


if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("recipe_dir")
    args = parser.parse_args()

    test_package(args.recipe_dir)

    import sys

    sys.exit(0)
