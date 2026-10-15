${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
          -Csetup-args="--cross-file=$MESON_CROSS_PYTHON_FILE" \
          -Csetup-args="-Dc_thread_count=0"
