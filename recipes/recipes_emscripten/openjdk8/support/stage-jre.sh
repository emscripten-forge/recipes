#!/bin/bash
# stage-jre.sh -- prepare the Java runtime file tree that the browser loads
# into its virtual file system (mounted at /java).
#
# usage: stage-jre.sh BUILD_DIR LINK_OUT_DIR DEST
# The native libraries are part of openjdk8.wasm; in the file tree they are
# replaced by empty placeholders so that the JDK's library lookups (which
# check that the files exist) keep working.
set -euo pipefail
BUILD=$(cd "$1" && pwd)
LINKOUT=$(cd "$2" && pwd)
DEST=$3
SUPPORT=${SUPPORT:-$(cd "$(dirname "$0")" && pwd)}

rm -rf "$DEST"
mkdir -p "$DEST"
cp -a "$BUILD/images/j2re-image/." "$DEST/"
find "$DEST/lib/wasm32" -name '*.so' -exec sh -c ': > "$1"' _ {} \;
: > "$DEST/lib/wasm32/libwasmrt.so"
# launchers are not used in the browser (openjdk8.wasm is the launcher)
find "$DEST/bin" -type f ! -name java -delete
printf '#!/bin/sh\necho "java: run openjdk8.js / openjdk8.wasm instead" >&2\nexit 1\n' > "$DEST/bin/java"
rm -rf "$DEST/man" "$DEST/lib/wasm32/libjsig.so" "$DEST/lib/wasm32/libawt_headless.so" \
       "$DEST/lib/wasm32/libsplashscreen.so"
cp "$LINKOUT/wasm-runtime.jar" "$DEST/lib/ext/"
if [ -d "$SUPPORT/jre-overlay" ]; then
  cp -a "$SUPPORT/jre-overlay/." "$DEST/"
fi
# DejaVu fonts for the logical fonts (see jre-overlay/lib/fontconfig.properties),
# from the font-ttf-dejavu package
FONT_DIR=${FONT_DIR:-${BUILD_PREFIX:-}/fonts}
mkdir -p "$DEST/lib/fonts"
for f in DejaVuSans DejaVuSans-Bold DejaVuSans-Oblique DejaVuSans-BoldOblique \
         DejaVuSerif DejaVuSerif-Bold DejaVuSerif-Italic DejaVuSerif-BoldItalic \
         DejaVuSansMono DejaVuSansMono-Bold DejaVuSansMono-Oblique DejaVuSansMono-BoldOblique; do
  cp "$FONT_DIR/$f.ttf" "$DEST/lib/fonts/"
done
