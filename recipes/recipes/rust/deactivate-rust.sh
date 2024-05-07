#!/bin/bash

echo "Deactivating Rust"

unset CARGO_HOME
unset RUSTUP_HOME



# is there a .bashenv.bak file?
if [ -f ${HOME}/.bashenv.bak ]; then
    # restore the .bashenv file
    echo "Restoring .bashenv file"
    mv ${HOME}/.bashenv.bak ${HOME}/.bashenv
fi

# is there a .bash_profile.bak file?
if [ -f ${HOME}/.bash_profile.bak ]; then
    # restore the .bash_profile file
    echo "Restoring .bash_profile file"
    mv ${HOME}/.bash_profile.bak ${HOME}/.bash_profile
fi