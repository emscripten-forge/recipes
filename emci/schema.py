import re
from pydantic import BaseModel, field_validator
from typing import Optional

class Source(BaseModel):
    url: str
    sha256: str

    @field_validator("url")
    @classmethod
    def validate_url_or_template(cls, v: str) -> str:
        # Allow templated strings like ${{ version }}
        if "${{" in v and "}}" in v:
            return v
        # Otherwise, check it’s a valid URL
        if not re.match(r"^https://.*\.(tar\.gz|zip)$", v):
            raise ValueError("source.url must be a valid HTTPS link to .tar.gz or .zip, or contain templating")
        return v

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
    source: Source
