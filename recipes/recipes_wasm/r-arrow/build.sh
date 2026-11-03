#!/bin/bash

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"

cd r
$R CMD INSTALL $R_ARGS .
