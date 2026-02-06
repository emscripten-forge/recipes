import sys
import traceback

print("=== PyArrow Import Debug ===")
print("Python version:", sys.version)
print("Python path:", sys.path)

try:
    print("\n1. Testing import of pyarrow...")
    import pyarrow
    print("SUCCESS: pyarrow imported successfully")
    print("PyArrow version:", pyarrow.__version__)
except Exception as e:
    print("FAILED: Exception during import")
    print(f"Exception type: {type(e).__name__}")
    print(f"Exception message: {repr(e)}")
    print(f"Exception args: {e.args}")
    print("\nFull traceback:")
    traceback.print_exc()
    sys.exit(1)

print("\n=== All tests passed ===")
