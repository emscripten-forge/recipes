# Browser tests for the openjdk8 package

These run the demo pages of the installed package in headless Chrome
(needs Node.js, `npm install puppeteer-core`, and Chrome/chrome-headless-shell
137 or later for WebAssembly JSPI):

```sh
D=$PREFIX/share/openjdk8-wasm
export CHROME=/path/to/chrome-headless-shell
# applets: AWT applet (animation, image, sound, LiveConnect, drawing) + Swing JApplet
node run_page.js $D demo/applets.html --wait "APPLET INIT" --actions applets.json --timeout 300
# Swing application started with OpenJDK8.run()
node run_page.js $D demo/app.html --wait "SWING DEMO VISIBLE" --actions app.json --timeout 300
```

`run_page.js` serves the directory over HTTP, prints the page's console
output, replays the mouse/keyboard actions of the JSON file once the marker
text appears, and exits with status 0 when all actions completed.  Pass
`CHROME_ARGS=--autoplay-policy=no-user-gesture-required` to let the page
start Web Audio without a click.
