library(reticulate)

import("os")

print("we are here")

# add 2+2 via python
print(py_eval("2 + 2"))