# Smoke test of pyjs-dev in a browser (run by pyjs-code-runner, see
# recipe.yaml): python <-> JavaScript in both directions. Any exception fails
# the run. (The full test suite runs in the CI of the pyjs repository.)
import pyjs
from pyjs import js

# python -> JavaScript
assert js.Math.max(3, 7) == 7
assert js.Array.of(1, 2, 3).length == 3

# JavaScript -> python
add = js.Function("f", "return f(2, 3)")
assert add(lambda a, b: a + b) == 5

# deep conversion
assert pyjs.to_py(js.JSON.parse('{"a": [1, 2, {"b": "c"}]}')) == {"a": [1, 2, {"b": "c"}]}

print("pyjs smoke test passed")
