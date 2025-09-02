import pure_eval
import ast

# Test basic functionality
expr = ast.parse("1 + 2", mode='eval')
result = pure_eval.eval_with_name_dict(expr, {})
assert result == 3

print("pure_eval basic functionality test passed")