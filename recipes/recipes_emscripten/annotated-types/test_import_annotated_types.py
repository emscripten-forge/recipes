import annotated_types
from typing import Annotated

# Test basic functionality
Ge5 = Annotated[int, annotated_types.Ge(5)]
print("annotated_types import test passed")