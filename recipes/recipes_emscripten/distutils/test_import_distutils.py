import distutils
import distutils.core
import distutils.util

# Test basic distutils functionality
print("distutils imported successfully")
print("distutils version:", getattr(distutils, '__version__', 'unknown'))

# Test core distutils components
try:
    from distutils.core import setup
    print("distutils.core.setup imported successfully")
except ImportError as e:
    print("Failed to import distutils.core.setup:", e)

try:
    from distutils.util import get_platform
    platform = get_platform()
    print("Platform detected by distutils:", platform)
except ImportError as e:
    print("Failed to import distutils.util.get_platform:", e)

try:
    from distutils.sysconfig import get_config_vars
    print("distutils.sysconfig imported successfully")
except ImportError as e:
    print("Failed to import distutils.sysconfig:", e)

print("All distutils tests passed!")