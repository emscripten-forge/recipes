#!/usr/bin/env bash
# Builds and runs Java programs with the package: a console build under node
# (core APIs, threads, NIO, crypto, every collector, javac/source launcher)
# and a browser build with AWT/Swing on x11.wasm (linked; running it needs a
# browser -- see share/openjdk21-wasm/shell.html).
set -euxo pipefail
unset JAVA_TOOL_OPTIONS || true

LINK="$PREFIX/bin/openjdk21-wasm-link"
JAVAC="$(command -v javac || echo "$BUILD_PREFIX/lib/jvm/bin/javac")"

mkdir -p classes out
"$JAVAC" --release 21 -d classes tests/Hello.java tests/GcStress.java tests/SwingDemo.java

"$LINK" --node -o out/node/jvm.js --app classes@/app/classes --app tests/Hi.java@/app/src/Hi.java

node out/node/jvm.js -version

node out/node/jvm.js -cp /app/classes Hello | tee hello.log
grep -q 'ALL TESTS PASSED' hello.log

for gc in -XX:+UseSerialGC -XX:+UseParallelGC -XX:+UseG1GC \
          "-XX:+UnlockExperimentalVMOptions -XX:+UseEpsilonGC"; do
  # shellcheck disable=SC2086
  node out/node/jvm.js $gc -Xmx128m -cp /app/classes GcStress 10 | tee gc.log
  grep -q 'GcStress done total=' gc.log
done

# javac running inside the wasm JVM (source-file mode compiles in memory)
node out/node/jvm.js /app/src/Hi.java x | tee hi.log
grep -q 'compiled in wasm: Point\[x=4, y=16\] args=x' hi.log

# browser build with the X11 toolkit
"$LINK" -o out/web/swing.html --app classes@/app/classes \
  --arg -cp --arg /app/classes --arg SwingDemo
test -s out/web/swing.wasm
test -s out/web/swing.html
