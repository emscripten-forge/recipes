#!/bin/bash
set -euxo pipefail

run() {
    node "${PREFIX}/bin/$1" "${@:2}"
}

# number of triangulations of a square: 2
square='[[0,0,1],[1,0,1],[0,1,1],[1,1,1]]'
test "$(echo "${square}" | run points2ntriangs 2>/dev/null)" = "2"

# convex hexagon: Catalan number C_4 = 14
hexagon='[[2,0,1],[1,2,1],[-1,2,1],[-2,0,1],[-1,-2,1],[1,-2,1]]'
test "$(echo "${hexagon}" | run points2ntriangs 2>/dev/null)" = "14"

# 3-cube: 74 triangulations
cube3='[[0,0,0,1],[1,0,0,1],[0,1,0,1],[1,1,0,1],[0,0,1,1],[1,0,1,1],[0,1,1,1],[1,1,1,1]]'
test "$(echo "${cube3}" | run points2ntriangs 2>/dev/null)" = "74"

# the cube generator program runs and prints a point configuration
run cube 3 > cube.txt
cat cube.txt
grep -F "[" cube.txt

# a triangulation of the square is regular
echo "${square}" | run points2finetriang 2>/dev/null | tee fine.txt
test -s fine.txt
