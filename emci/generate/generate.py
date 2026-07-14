
# enum
import enum

from .cran import generate_r_cran_recipe

# enum for recipe types
class PackageType(enum.Enum):

    python = "python"
    r_cran = "r-cran"





def generate_recipe(name, type, maintainer, outdir):
    if type == PackageType.r_cran:
        generate_r_cran_recipe(name, type, maintainer, outdir)
    else:
        raise ValueError(f"Unsupported package type: {type}")
    