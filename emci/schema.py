import re
from pydantic import BaseModel, field_validator
from typing import Optional

class Source(BaseModel):
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
            if not re.match(r"^https://.*\.(tar\.gz|tar\.bz2|tar\.xz)$", url):
                raise ValueError(f"{url} must be a valid link to an archive file (tar.gz, tar.bz2, etc.)\n")

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

class About(BaseModel):
    license: str
    license_file: str | list[str]
    license_family: Optional[str] = None


class Recipe(BaseModel):
    about: About
    source: Optional[Source] = None
