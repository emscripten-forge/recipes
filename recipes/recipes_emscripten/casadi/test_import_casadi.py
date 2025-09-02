#!/usr/bin/env python

import casadi

# Basic import test
print("CasADi version:", casadi.__version__)

# Test basic symbolic computation
x = casadi.SX.sym('x')
y = x**2 + 1

print("Created symbolic expression:", y)
print("CasADi import test successful!")