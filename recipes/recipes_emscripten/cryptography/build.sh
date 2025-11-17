#!/bin/bash



# $PREFIX/bin/python is wrongly used?

# # remove $PREFIX/bin/python
# rm -f ${PREFIX}/bin/python

# # create a symlink to $PYTHON


$PREFIX/bin/python - << 'EOF'
import platform, sys
print("system:", platform.system())
print("platform:", platform.platform())
print("sysconfig:", __import__("sysconfig").get_platform())
EOF





${PYTHON} -m pip  install . -vvv

