import re
from pydantic import BaseModel, field_validator, model_validator
from typing import Optional, Any, Union

class PathSource(BaseModel):
    """Source with local path (e.g., pytester recipe)"""
    path: str
    target_directory: Optional[str] = None

class UrlSource(BaseModel):
    """Source with URL and SHA256 (standard remote sources)"""
    url: str | list[str]
    sha256: str

    @field_validator("url")
    @classmethod
    def validate_url_or_template(cls, v: str | list[str]) -> str | list[str]:
        def validate_single_url(url: str) -> str:
            # Check version template
            if not ("${{version" in url.replace(" ", "") and "}}" in url):
                raise ValueError(f"{url} must contain ${{{{ version }}}} for automatic updates.\n")
            # Check it's a valid URL
            if not re.match(r"^(https://.*|http://.*)\.(tar\.gz|tar\.bz2|tar\.xz|tgz|zip)$", url):
                raise ValueError(f"{url} must be a valid link (https://...) to an archive file (tar.gz, tar.bz2, tar.xz, .tgz, or .zip)\n")

            return url

        if isinstance(v, list):
            return [validate_single_url(url) for url in v]
        else:
            return validate_single_url(v)

    @field_validator("sha256")
    @classmethod
    def validate_sha256(cls, v: str) -> str:
        if not re.match(r"^[0-9a-f]{64}$", v):
            raise ValueError("source.sha256 must be a 64-character hex string")
        return v

# Union type for source - can be either path-based or URL-based
Source = Union[PathSource, UrlSource]

class About(BaseModel):
    license: str
    license_file: str | list[str]
    license_family: Optional[str] = None


class Build(BaseModel):
    number: int

    @field_validator("number")
    @classmethod
    def validate_build_number(cls, v: int) -> int:
        if not (4000 <= v < 5000):
            raise ValueError("build.number must be greater than or equal to 4000 and less than 5000")
        return v


class Recipe(BaseModel):
    about: About
    source: Optional[Union[Source, list[PathSource]]] = None
    build: Build
    tests: Optional[Any] = None

    @model_validator(mode='before')
    @classmethod
    def check_tests_exists(cls, values):
        if 'tests' not in values or values['tests'] is None:
            if 'outputs' in values:
                for output_dict in values['outputs']:
                    if 'tests' not in output_dict:
                        pkg_name = output_dict.get('package', {}).get('name', 'unknown')
                        raise AttributeError(f"Output '{pkg_name}' must have a 'tests' section.")
            else:
                raise AttributeError("Recipe must have a 'tests' section.")

        return values

    @model_validator(mode='after')
    def validate_source(self):
        """Validate that non-path sources have url and sha256"""
        if self.source is None:
            return self

        # Handle list of path sources (e.g., pytester)
        if isinstance(self.source, list):
            # All elements should be PathSource, which is already validated
            return self

        # Handle single source - check the model type
        if isinstance(self.source, PathSource):
            # PathSource is valid - no url/sha256 needed
            return self

        if isinstance(self.source, UrlSource):
            # UrlSource already requires sha256 via field definition, so it's valid
            return self

        # If we get here, something unexpected happened
        return self
