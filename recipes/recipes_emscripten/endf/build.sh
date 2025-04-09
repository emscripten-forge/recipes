# Apply any necessary Emscripten-specific flags
export CFLAGS="${CFLAGS} -s USE_PTHREADS=0"
export CXXFLAGS="${CXXFLAGS} -s USE_PTHREADS=0"
export LDFLAGS="${LDFLAGS} -s USE_PTHREADS=0"

# Use pip to build the package
${PYTHON} -m pip install . --no-deps -vv