#!/usr/bin/env python3
"""Serve a directory with the headers a threaded wasm program needs.

SharedArrayBuffer (and so pthreads) is only available to cross-origin
isolated pages: the document must be served with
Cross-Origin-Opener-Policy: same-origin and
Cross-Origin-Embedder-Policy: require-corp.

    python3 serve.py [DIR] [PORT]
"""
import functools
import http.server
import sys


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      ".wasm": "application/wasm", ".js": "text/javascript"}

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def main():
    directory = sys.argv[1] if len(sys.argv) > 1 else "."
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8000
    handler = functools.partial(Handler, directory=directory)
    with http.server.ThreadingHTTPServer(("127.0.0.1", port), handler) as httpd:
        print(f"serving {directory} on http://127.0.0.1:{port}/")
        httpd.serve_forever()


if __name__ == "__main__":
    main()
