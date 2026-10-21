# JAVA

We provide `openjdk21` and `openjdk8` packages in emscripten-forge that allow running unmodified `.jar` executables and java applets in the browser, without a Java server.

## openjdk21 recipe documentation:

Create one environment with the tools (`openjdk21-wasm-link` and the Emscripten
toolchain it uses), and one with the JVM:

```bash
CH="-c https://repo.prefix.dev/emscripten-forge-4x -c conda-forge"
micromamba create -y -n env_tools $CH openjdk-tools
micromamba activate env_tools
micromamba create -y -p ./jdk21env --platform emscripten-wasm32 $CH openjdk21
```

Link your application into a page:

```bash
openjdk21-wasm-link --prefix ./jdk21env -o out/app.html --app path/to/app.jar --arg -jar --arg /app/app.jar
```

Packing a multi-file jar or a directory is supported, for example
```bash
openjdk21-wasm-link --prefix ./jdk21env -o out/multifilejar.html --app ./multifilejardir --arg -jar --arg /app/multifilejardir/jarsdir/jarexecutable.jar
```

| Option | Description |
|---|---|
| `--prefix DIR` | The emscripten-wasm32 environment with `openjdk21`. **Required.** |
| `-o FILE` | Output file, `.html` or `.js`. **Required.** |
| `--app SRC[@DEST]` | Copy a host file or directory into the virtual file system (default `DEST`: `/app/<basename>`). Repeatable. |
| `--arg ARG` | Default Java command-line argument. Repeatable. Under node, command-line arguments override these; in the browser, `?args=a,b` in the page URL overrides them. |
| `--env NAME=VALUE` | Environment variable for the program. Repeatable. In the browser, the page URL can set more with `?env=NAME=VALUE,...`; these are added to the `--env` ones and replace any with the same name. |
| `--headless` | No display: uses `libawt_headless` and leaves out x11.wasm. |
| `--node` | Build for node (the program exits when `main` returns). Implies `--headless`. |
| `--max-memory MB` | Maximum wasm memory (default `2048`). |
| `--pool N` | Number of pre-started pthread workers (default `12`). |
| `--opt LEVEL` | emcc optimisation level for the link (default `-O2`). |
| `--module` | Link only the runtime, as a module like the prelinked one below (`-o DIR/openjdk21.js`). |
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
  `python3 $CONDA_PREFIX/share/openjdk-tools/serve.py out 8000` (in `env_tools`).

Either way, the page must be served over HTTPS or from `localhost`; browsers
ignore these headers on other plain-http addresses. Opening the file directly
(`file://`) does not work either: service workers only run on http(s) pages,
and the browser won't load the `.wasm` and `.data` files from `file://`.

If you link to `.js` instead of `.html`, no service worker is added. Your page
must then send the headers itself. None of this applies to
programs linked with `--node`.

#### Prelinked runtime

The `openjdk21` package also contains the runtime already linked, like
`openjdk8` does, so a page can run Java without `openjdk21-wasm-link`. Copy
these files into one directory on your web server:

```bash
ls jdk21env/share/openjdk21-wasm/
# openjdk21-web.js  openjdk21.js  openjdk21.wasm  openjdk21-jre.json
# openjdk21-jre.data.gz  coi-serviceworker.js  ...
```

and start Java from a page, listing the files the program needs:

```html
<div id="x11-wasm-root" style="position:relative;width:800px;height:600px"></div>
<script src="/jvm/openjdk21-web.js"></script>
<script>
  OpenJDK21.run({
    args: ['-jar', '/app/app.jar'],
    root: document.getElementById('x11-wasm-root'),   // where Java windows are drawn
    files: { '/app/app.jar': 'app.jar' },              // VM path: URL to fetch
    onExit: function (status) { console.log('Java exited with ' + status); },
  });
</script>
```

The page must be cross-origin isolated, as above. If the server doesn't send
the headers, `openjdk21-web.js` loads `coi-serviceworker.js` from its own
directory; a service worker only covers pages in its directory and below, so
put the page next to the files (or in a subdirectory) in that case.
`OpenJDK21.run` also takes `env`, `jvmArgs`, `heap` (e.g. `'512m'`),
`onStdout`, `onStderr`, `onProgress`, `documentTitle: false` (keep the page
title) and `stdin: true` (then feed `System.in` with `module.writeStdin(text)`
and `module.closeStdin()` on the module the returned promise gives).

`openjdk21-java` from `openjdk-tools` runs the same prelinked runtime under
Node.js, like the `java` command (headless AWT; the host's files are visible):

```bash
OPENJDK21_WASM_HOME=./jdk21env/share/openjdk21-wasm openjdk21-java -cp classes Main
```

## openjdk8 recipe documentation:

`openjdk8` runs Java applets in the browser. It can also run plain Java desktop
programs.

Install the package and copy its browser files into one directory on your
web server:

```bash
micromamba create -y -p ./jdk8env --platform emscripten-wasm32 -c https://repo.prefix.dev/emscripten-forge-4x -c conda-forge openjdk8
ls jdk8env/share/openjdk8-wasm/
# openjdk8-web.js  openjdk8.js  openjdk8.wasm  openjdk8-jre.json  openjdk8-jre.data.gz
# openjdk8-javaws.jar
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

#### Java Web Start

On a page that loads `openjdk8-web.js`, following a link to a `.jnlp` file
starts that application with Java Web Start, as a browser with Java installed
did:

```html
<script src="/jvm/openjdk8-web.js"></script>
<a href="app/launch.jnlp">Launch the application</a>
```

Web Start is IcedTea-Web's `javaws`, in `openjdk8-javaws.jar`, which is only
downloaded when it is needed. It reads the JNLP file, downloads the jars,
shows the usual security dialogs (unsigned code, certificates, missing
manifest attributes), and runs the application in the sandbox or with the
permissions it was granted; the JNLP services (`javax.jnlp.BasicService`,
...) work. The application's windows appear in a layer over the page. Call
`OpenJDK8.runJNLP(url, options)` to start one from a script, and add
`data-jnlp="off"` to the script tag to leave `.jnlp` links alone. The JNLP
file and its jars are fetched by the page, so they must come from the same
origin (or be served with CORS headers). Give the JNLP file a `codebase`, as
JNLP files normally have: without one, `javaws` treats the application as a
local file and asks whether to run code from its location. Each page runs one
Java VM, so it runs one Web Start application at a time.

`run()` and `runJNLP()` also take `windowManager: true`, which lets x11.wasm
draw title bars on top-level windows so they can be moved and closed
(`OpenJDK21.run` takes it too). It is experimental: with AWT the title bar
shows the name of a hidden helper window ("FocusProxy") rather than the
frame's title.

#### Outside the browser

Outside the browser, `openjdk8-java` from the `openjdk-tools` package (see the
openjdk21 section) runs Java programs under Node.js 24 or later, with headless
AWT, like the `java` command, and `openjdk8-javaws` runs JNLP files. Point
them at the `openjdk8` environment:

```bash
export OPENJDK8_WASM_HOME=./jdk8env/share/openjdk8-wasm
openjdk8-java -cp classes Main
openjdk8-javaws app.jnlp
```
