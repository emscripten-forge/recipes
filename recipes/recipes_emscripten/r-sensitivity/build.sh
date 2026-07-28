#!/bin/bash


file=DESCRIPTION

sed -i.bak 's/, dtwclust//' "$file" && rm -f "$file.bak"

$R CMD INSTALL $R_ARGS .