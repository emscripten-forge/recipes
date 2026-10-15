# JAVA

We provide `openjdk21` and `openjdk8` packages in emscripten-forge that allow running unmodified `.jar` executables and java applets in the browser, without a Java server.

## openjdk21 recipe documentation:

Create one environment with the JVM, and one with the Emscripten toolchain:

```bash
CH="-c https://repo.prefix.dev/emscripten-forge-4x -c conda-forge"
micromamba create -y -p ./javaenv --platform emscripten-wasm32 $CH openjdk21
micromamba create -y -p ./emenv $CH emscripten_emscripten-wasm32=4.0.9
```

Link your application into a page:

```bash
PATH=$PWD/emenv/bin:$PATH ./javaenv/bin/openjdk21-wasm-link -o out/app.html --app path/to/app.jar --arg -jar --arg /app/app.jar
```

Packing a multi-file jar or a directory is supported, for example
```
PATH=$PWD/emenv/bin:$PATH ./javaenv/bin/openjdk21-wasm-link -o out/multifilejar.html --app .
./multifilejardir --arg -jar --arg /app/multifilejardir/jarsdir/jarexecutable.jar
```

| Option | Description |
|---|---|
| `-o FILE` | Output file, `.html` or `.js`. **Required.** |
| `--app SRC[@DEST]` | Copy a host file or directory into the virtual file system (default `DEST`: `/app/<basename>`). Repeatable. |
| `--arg ARG` | Default Java command-line argument. Repeatable. Under node, command-line arguments override these; in the browser, `?args=a,b` in the page URL overrides them. |
| `--env NAME=VALUE` | Environment variable for the program. Repeatable. In the browser, the page URL can set more with `?env=NAME=VALUE,...`; these are added to the `--env` ones and replace any with the same name. || `--headless` | No display: uses `libawt_headless` and leaves out x11.wasm. |
| `--node` | Build for node (the program exits when `main` returns). Implies `--headless`. |
| `--max-memory MB` | Maximum wasm memory (default `2048`). |
| `--pool N` | Number of pre-started pthread workers (default `12`). |
| `--opt LEVEL` | emcc optimisation level for the link (default `-O2`). |
| `--` | Pass everything after it to emcc. |

#### Hosting the page

For this openjdk21 recipe, `SharedArrayBuffer` is needed. It must be served with these two headers:

    Cross-Origin-Opener-Policy: same-origin
    Cross-Origin-Embedder-Policy: require-corp

You don't need to configure them yourself:

- When the output is an `.html` page, `openjdk21-wasm-link` copies
  `coi-serviceworker.js` next to it, and the page loads it. If the server
  doesn't send the headers, this service worker adds them in the browser and
  reloads the page. This makes the page work on static hosts such as GitHub
  Pages. Keep `coi-serviceworker.js` in the same directory as the page.
- For local testing, `serve.py` sends the headers directly:
  `python3 javaenv/share/openjdk21-wasm/serve.py out 8000`.

Either way, the page must be served over HTTPS or from `localhost`; browsers
ignore these headers on other plain-http addresses. Opening the file directly
(`file://`) does not work either: service workers only run on http(s) pages,
and the browser won't load the `.wasm` and `.data` files from `file://`.

If you link to `.js` instead of `.html`, no service worker is added. Your page
must then send the headers itself. None of this applies to
programs linked with `--node`.

## openjdk8 recipe documentation:

`openjdk8` runs Java applets in the browser. It can also run plain Java desktop
programs.

Install the package and copy its five browser files into one directory on your
web server:

```bash
micromamba create -y -p ./jdk8env --platform emscripten-wasm32 -c https://repo.prefix.dev/emscripten-forge-4x -c conda-forge openjdk8
ls jdk8env/share/openjdk8-wasm/
# openjdk8-web.js  openjdk8.js  openjdk8.wasm  openjdk8-jre.json  openjdk8-jre.data.gz
```

Then load `openjdk8-web.js` on the page that contains the applet:

```html
<script src="/jvm/openjdk8-web.js"></script>
<applet code="MyApplet.class" codebase="classes/" archive="my.jar" width="400" height="300">
  <param name="foo" value="bar">
</applet>
```

Replace `/jvm/` with wherever you put the files. The loader loads the other
files from its own directory (or from a `data-base="..."` attribute on the
script tag). When the page has loaded, it starts every `<applet>`, and every
Java `<object>` or `<embed>`, in a single Java VM. To start them yourself
instead, add `data-applets="off"` to the script tag and call
`OpenJDK8.runApplets()`.

To run a program instead of an applet, call `OpenJDK8.run()` and list the
files the program needs:

    OpenJDK8.run({
      args: ['-cp', '/app', 'Main'],
      root: element,                          // where Java windows are drawn
      files: { '/app/Main.class': 'Main.class' } // VM path: URL to fetch
    })

Outside the browser, `bin/openjdk8-java` runs Java programs under Node.js 24 or
later, with headless AWT, like the `java` command.
