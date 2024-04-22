#!/bin/bash

echo "Deactivating Rust"

unset CARGO_HOME
unset RUSTUP_HOME

rustup self uninstall -y