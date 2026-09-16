// qt-wasm-runner: fetch an emscripten-forge Qt6-wasm package as .tar.bz2,
// extract it entirely in the browser, and boot the app.
//
// Uses @emscripten-forge/untarjs for bz2 decode + tar walk. The extracted
// contents are turned into blob: URLs so Qt's loader can fetch them without
// touching the network.

import { initUntarJS } from "https://esm.sh/@emscripten-forge/untarjs@5.3.3";

// Point untarjs's internal Emscripten module at unpack.wasm via a proper
// URL. Its bundled default is a raw Uint8Array of the wasm bytes, which
// only works when a bundler pre-processes it; via esm.sh, Emscripten later
// calls startsWith() on those bytes and crashes. Hosting the sidecar on
// jsdelivr (CORS-friendly, immutable versioned URL) avoids that.
const UNTAR_WASM_URL =
  "https://cdn.jsdelivr.net/npm/@emscripten-forge/untarjs@5.3.3/lib/unpack.wasm";

const statusEl  = document.getElementById("status");
const screenEl  = document.getElementById("screen");
const urlInput  = document.getElementById("url");
const runBtn    = document.getElementById("load");
const fileInput = document.getElementById("file");
const helpBtn   = document.getElementById("help-btn");
const shareBtn  = document.getElementById("share");

// Show help by default (nothing loaded); toggle via the ? button or by
// starting to load a package.
document.body.classList.add("show-help");
helpBtn.addEventListener("click", () => {
  document.body.classList.toggle("show-help");
});
function hideHelp() {
  document.body.classList.remove("show-help");
}

function setStatus(msg, isError = false) {
  statusEl.textContent = msg;
  statusEl.classList.toggle("error", isError);
}

function loadScript(src) {
  return new Promise((resolve, reject) => {
    const s = document.createElement("script");
    s.src = src;
    s.onload = () => resolve();
    s.onerror = () => reject(new Error(`failed to load ${src}`));
    document.head.appendChild(s);
  });
}

// A conda .tar.bz2 lays out installable files under a per-app path like
// `share/qt-calculator/{qt-calculator.wasm, qt-calculator.js, qt-calculator.html, qtloader.js}`.
// Find the app directory by locating the sole share/*/ *.wasm file.
function findAppDir(files) {
  const wasmPaths = Object.keys(files).filter(
    p => p.endsWith(".wasm") && p.startsWith("share/")
  );
  if (wasmPaths.length === 0) {
    throw new Error("no share/*/ *.wasm file in the package");
  }
  if (wasmPaths.length > 1) {
    console.warn("multiple wasm files found, picking first:", wasmPaths);
  }
  const wasm = wasmPaths[0];
  const dir = wasm.slice(0, wasm.lastIndexOf("/"));       // e.g. "share/qt-calculator"
  const name = wasm.slice(dir.length + 1, -".wasm".length); // e.g. "qt-calculator"
  return { dir, name };
}

// source is either a URL string (fetched by untarjs) or a Uint8Array
// (already-loaded bytes from a File/drop). untarjs 5.3.3 exposes two
// separate methods: extract(url) fetches then extracts, extractData(bytes)
// works on already-loaded bytes.
// Detect whether this browser can actually run JSPI-linked wasm. Some
// browsers expose WebAssembly.Suspending as a type but haven't unlocked
// the constructor form yet (Firefox: needs the
// javascript.options.wasm_js_promise_integration pref in about:config;
// older Chrome required a flag; Safari status varies). Returns a friendly
// diagnostic string when it won't work, or null if it will.
function jspiUnavailableReason() {
  if (typeof WebAssembly.Suspending !== "function") {
    if (/Firefox/.test(navigator.userAgent)) {
      return "JSPI isn't enabled in this Firefox. Open about:config and set javascript.options.wasm_js_promise_integration to true, then reload.";
    }
    return "This browser doesn't expose the JSPI (JavaScript Promise Integration) API. Try Chrome or Edge 137+, or a recent Firefox with the JSPI pref enabled.";
  }
  try {
    new WebAssembly.Suspending(() => Promise.resolve());
    return null;
  } catch (_e) {
    if (/Firefox/.test(navigator.userAgent)) {
      return "JSPI is partially exposed but its Suspending constructor isn't usable. Set javascript.options.wasm_js_promise_integration to true in about:config, then reload.";
    }
    return "JSPI is partially exposed but its Suspending constructor isn't usable in this browser. Try Chrome or Edge 137+.";
  }
}

async function run(source, label = String(source)) {
  hideHelp();

  const jspiFail = jspiUnavailableReason();
  if (jspiFail) {
    setStatus(jspiFail, true);
    return;
  }

  // Reflect the current package URL in location.search so the address bar
  // is always a shareable deep-link. Only makes sense for URL-based loads;
  // for file/drop there's nothing to link to.
  if (typeof source === "string") {
    const params = new URLSearchParams(location.search);
    params.set("pkg", source);
    history.replaceState(null, "", "?" + params.toString());
  }

  try {
    setStatus(`loading ${label}…`);

    const untarjs = await initUntarJS(() => UNTAR_WASM_URL);
    const files = typeof source === "string"
      ? await untarjs.extract(source)
      : await untarjs.extractData(source);
    setStatus(`extracted ${Object.keys(files).length} files, locating app…`);

    const { dir, name } = findAppDir(files);
    setStatus(`booting ${name}…`);

    // Build a base-name → blob: URL map for everything in the app dir.
    // Qt's loader will look up `<name>.wasm` by base name, so this makes
    // its file-fetching work without any real HTTP.
    const blobs = {};
    for (const [path, bytes] of Object.entries(files)) {
      if (!path.startsWith(dir + "/")) continue;
      const rel = path.slice(dir.length + 1);
      // Set MIME type so WebAssembly.instantiateStreaming accepts the
      // .wasm blob and the browser treats .js as JS. Without this,
      // Emscripten warns "Incorrect response MIME type" and falls
      // back to the slower ArrayBuffer instantiation path.
      const type = rel.endsWith(".wasm") ? "application/wasm"
                 : rel.endsWith(".js")   ? "text/javascript"
                 : rel.endsWith(".html") ? "text/html"
                 : "";
      blobs[rel] = URL.createObjectURL(new Blob([bytes], { type }));
    }

    if (!blobs[`${name}.js`] || !blobs["qtloader.js"]) {
      throw new Error(`missing ${name}.js or qtloader.js in package`);
    }

    // Load qtloader.js first (defines global qtLoad).
    await loadScript(blobs["qtloader.js"]);
    // Then the app's emscripten glue (defines global <name>_entry).
    await loadScript(blobs[`${name}.js`]);

    const entryName = name.replaceAll("-", "_") + "_entry";
    const entry = window[entryName];
    if (typeof entry !== "function") {
      throw new Error(`emscripten entry ${entryName} not found on window`);
    }

    await window.qtLoad({
      qt: {
        // Wrap Emscripten's entry so locateFile resolves to our blob URLs
        // — the wasm fetch goes there instead of the real network.
        entryFunction: (config) =>
          entry({
            ...config,
            locateFile: (fname) => blobs[fname] ?? fname,
          }),
        containerElements: [screenEl],
        onLoaded: () => setStatus(`running ${name}`),
        onExit: (e) =>
          setStatus(`${name} exited: ${e.text ?? "code " + e.code}`, e.crashed),
      },
    });

    // Qt-wasm sometimes doesn't commit its initial canvas paint until it
    // receives a resize event (bug we hit with the qt-hello demo). Fire a
    // couple of synthetic resizes after boot to force the first frame.
    setTimeout(() => window.dispatchEvent(new Event("resize")), 100);
    setTimeout(() => window.dispatchEvent(new Event("resize")), 500);

    setStatus(`running ${name}`);
  } catch (err) {
    console.error(err);
    setStatus(`error: ${err.message ?? err}`, true);
  }
}

async function runFromFile(file) {
  setStatus(`reading ${file.name} (${(file.size / 1024 / 1024).toFixed(1)} MiB)…`);
  const bytes = new Uint8Array(await file.arrayBuffer());
  return run(bytes, file.name);
}

// UI wiring.
// Clicking Run navigates to ?pkg=<url> and lets the page-load path boot
// the app. Two reasons over calling run() directly: (1) a second load
// after the first would leave the previous wasm module alive and racing
// the new one, and (2) the URL bar always reflects the current package
// without extra bookkeeping.
runBtn.addEventListener("click", () => {
  const url = urlInput.value.trim();
  if (!url) return;
  const params = new URLSearchParams();
  params.set("pkg", url);
  const target = "?" + params.toString();
  // If the URL didn't change (user re-clicked with same URL), force a
  // reload; otherwise a navigation to the same href is a no-op.
  if (location.search === target) location.reload();
  else location.search = target;
});
// Qt-wasm's qtloader.js installs document-level keyboard/input listeners
// that swallow events (paste, Ctrl+V, arrow keys, etc.) before they reach
// DOM inputs outside its canvas. Stop propagation at capture phase on
// every keyboard/clipboard event targeting our URL input so it behaves
// like a normal text field even while a Qt app is running.
["keydown", "keyup", "keypress", "input", "beforeinput", "paste", "cut", "copy"].forEach((evt) => {
  urlInput.addEventListener(evt, (e) => e.stopPropagation(), true);
});
urlInput.addEventListener("keydown", (e) => {
  if (e.key === "Enter") runBtn.click();
});

// Preset picker: fill the URL input and immediately click Run.
document.getElementById("preset").addEventListener("change", (e) => {
  const url = e.target.value;
  if (!url) return;
  urlInput.value = url;
  runBtn.click();
});

fileInput.addEventListener("change", () => {
  const file = fileInput.files?.[0];
  if (file) runFromFile(file);
});

// Full-page drag & drop. Only intercepts when the drag actually contains
// a file — text/URL drops (e.g. dragging a URL from the browser's URL bar
// into our input) fall through to the browser's native behavior.
function isFileDrag(e) {
  const types = e.dataTransfer?.types;
  return types && Array.from(types).includes("Files");
}
function isInInput(e) {
  return e.target === urlInput;
}
let dragDepth = 0;
window.addEventListener("dragenter", (e) => {
  if (isInInput(e) || !isFileDrag(e)) return;
  e.preventDefault();
  if (++dragDepth === 1) document.body.classList.add("dragging");
});
window.addEventListener("dragover", (e) => {
  if (isInInput(e) || !isFileDrag(e)) return;
  e.preventDefault();
  e.dataTransfer.dropEffect = "copy";
});
window.addEventListener("dragleave", (e) => {
  if (isInInput(e) || !isFileDrag(e)) return;
  e.preventDefault();
  if (--dragDepth <= 0) {
    dragDepth = 0;
    document.body.classList.remove("dragging");
  }
});
window.addEventListener("drop", (e) => {
  if (isInInput(e) || !isFileDrag(e)) return;
  e.preventDefault();
  dragDepth = 0;
  document.body.classList.remove("dragging");
  const file = e.dataTransfer?.files?.[0];
  if (file) runFromFile(file);
});

// Chrome-hide toggle — collapses top/status bars for maximum app real
// estate. The toggle button itself stays visible in the corner. Also
// bound to the F key (skip when typing into an input).
const chromeToggle = document.getElementById("chrome-toggle");
function toggleChrome() {
  const hidden = document.body.classList.toggle("chrome-hidden");
  // Reflect the state in the URL so it survives reloads and is included
  // when the user hits Share.
  const params = new URLSearchParams(location.search);
  if (hidden) params.set("fullscreen", "1");
  else params.delete("fullscreen");
  const search = params.toString();
  history.replaceState(null, "", search ? "?" + search : location.pathname);
  // After a hide/show the widget below may need a repaint prompt.
  window.dispatchEvent(new Event("resize"));
}
chromeToggle.addEventListener("click", toggleChrome);
document.getElementById("fullscreen-btn").addEventListener("click", toggleChrome);
document.addEventListener("keydown", (e) => {
  if (e.key !== "f" && e.key !== "F") return;
  if (e.target.matches("input, textarea")) return;
  if (e.ctrlKey || e.metaKey || e.altKey) return;
  toggleChrome();
});

// Share button — copies the current URL to clipboard. When a package is
// loaded (either via ?pkg= deep-link or by pressing Run URL), the URL bar
// already contains a deep-link to the exact package thanks to the
// history.replaceState call in run(). If nothing is loaded, we still copy
// the base runner URL (useful for sharing the runner itself).
// Share the current URL. Prefer the Web Share API (opens native share
// sheet: email, messaging apps, etc.), fall back to clipboard copy.
async function copyShareLink() {
  const url = location.href;
  const params = new URLSearchParams(location.search);
  const hasPkg = params.has("pkg");
  const title = hasPkg
    ? "Qt6 wasm app on qt-wasm-runner"
    : "qt-wasm-runner";

  if (navigator.share) {
    try {
      await navigator.share({ title, url });
      return;   // user picked a target or dismissed — either way, done
    } catch (err) {
      // AbortError = user cancelled the share sheet; treat as no-op.
      if (err && err.name === "AbortError") return;
      // Any other error (e.g., permission denied) — fall through to clipboard.
    }
  }

  try {
    await navigator.clipboard.writeText(url);
    setStatus(hasPkg
      ? "shareable link copied to clipboard"
      : "runner URL copied (no package loaded)");
  } catch (err) {
    setStatus(`clipboard write failed: ${err.message ?? err}`, true);
  }
}
shareBtn.addEventListener("click", copyShareLink);
document.getElementById("share-floating").addEventListener("click", copyShareLink);

// Exit — navigate to the base URL (no query params). Drops the running
// app, chrome-hidden state, and any deep-link params. The fresh page load
// lands on the initial state: chrome visible, help panel open. Wired to
// both the topbar Exit button and the floating × in the corner (which is
// the only reachable Exit while in fullscreen mode).
function doExit() { location.href = location.pathname; }
document.getElementById("exit").addEventListener("click", doExit);
document.getElementById("exit-floating").addEventListener("click", doExit);

// Show the JSPI warning as soon as the page loads if the browser is
// missing / gating it — so users don't have to click Run first to
// discover the incompatibility.
{
  const reason = jspiUnavailableReason();
  if (reason) setStatus(reason, true);
}

// Deep-link support: ?pkg=<url> autostarts; ?fullscreen=1 boots with the
// top/status bars hidden for embed-like use.
const params = new URLSearchParams(location.search);
if (params.get("fullscreen") === "1") {
  document.body.classList.add("chrome-hidden");
}
const pkgUrl = params.get("pkg");
if (pkgUrl) {
  urlInput.value = pkgUrl;
  run(pkgUrl);
}
